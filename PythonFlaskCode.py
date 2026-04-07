from flask import Flask, redirect, url_for, request, render_template, session
import psycopg2
import psycopg2.extras


app = Flask(__name__)
app.secret_key = "batman"

def get_db_connection():
    conn = psycopg2.connect(
        dbname="postgres",
        user="postgres",
        password="Database123",
        host="localhost",
        port="5432"
    )

    return conn

    


def get_data_from_database(start_date, end_date, room_capacity, area, hotel_chain, stars, totalRooms, price):
    conn = get_db_connection()
    cur = conn.cursor()

    query = """
        SELECT
            hc.chain_id,
            hc.hotel_name AS chain_name,
            h.hotel_id,
            h.city,
            h.province,
            h.star_number,
            r.room_id,
            r.capacity_of_room,
            r.price,
            count(r.room_id) OVER (PARTITION BY h.hotel_id) AS total_rooms
        FROM public.hotel_chain hc
        JOIN public.hotel h
            ON hc.chain_id = h.chain_id
        JOIN public.room r
            ON h.hotel_id = r.hotel_id
    """

    conditions = []
    parameters = []

    if room_capacity is not None and room_capacity != "":
        conditions.append("r.capacity_of_room = %s")
        parameters.append(room_capacity)

    if area is not None and area != "":
        conditions.append("h.city = %s")
        parameters.append(area)

    if hotel_chain is not None and hotel_chain != "":
        conditions.append("hc.hotel_name = %s")
        parameters.append(hotel_chain)

    if stars is not None and stars != "":
        conditions.append("h.star_number = %s")
        parameters.append(stars)

    if totalRooms is not None and totalRooms != "":
        conditions.append("total_rooms > %s")
        parameters.append(totalRooms)

    if price is not None and price != "":
        conditions.append("r.price <= %s")
        parameters.append(price)

    if start_date and end_date:
        conditions.append("""
            NOT EXISTS (
                SELECT 1
                FROM public.booking b
                WHERE b.hotel_id = r.hotel_id
                  AND b.room_id = r.room_id
                  AND b.start_date < %s
                  AND b.end_date > %s
            )
        """)
        parameters.append(end_date)
        parameters.append(start_date)

        conditions.append("""
            NOT EXISTS (
                SELECT 1
                FROM public.renting rt
                WHERE rt.hotel_id = r.hotel_id
                  AND rt.room_id = r.room_id
                  AND rt.start_date < %s
                  AND rt.end_date > %s
            )
        """)
        parameters.append(end_date)
        parameters.append(start_date)


    if conditions:
        query += " WHERE " + " AND ".join(conditions)

    query += " ORDER BY hc.chain_id, h.hotel_id, r.room_id"

    cur.execute(query, parameters)
    information = cur.fetchall()

    cur.close()
    conn.close()

    return information






@app.route("/")
def home():
    session.clear()
    return render_template("home_page.html")

    # list = get_data_from_database(None, None, None, None, None,  None, None, None)

    # string = ""

    # for x in list:
    #     string += str(x) +"<br><br>"

    # return string




@app.route("/rooms")
def room():
    capacity = request.args.get("capacity")
    price = request.args.get("price")
    area = request.args.get("area")

    string = ""

    if capacity:
        string += f" Capacity Received: {capacity}"
    else:
        string += " No Capacity Received"

    if price:
        string += f" Price Received: {price}"
    else:
        string += " No Price Received"

    if area:
        
        string += f" Area Received: {area}"
    else:
        string += " No Area Received"

    return "Rooms route is working " + string  



@app.route("/set-role", methods=["POST"])
def set_role():
    role = request.form["role"]
    session["role"] = role

    if role == "customer":
        return redirect(url_for("customer_login"))

    else:
        return render_template("employee_login.html")


@app.route("/search")
def search():
    return render_template("search.html")


@app.route("/view_bookings")
def view_bookings():
    return render_template("view_bookings.html")


@app.route("/views")
def views():
    return render_template("views.html")


@app.route("/customer_login", methods = ["GET", "POST"])
def customer_login():
    if request.method == "POST":
        conn = get_db_connection()
        curr = conn.cursor()

        customer_id = request.form["customer_id"]

        curr.execute(""" SELECT * FROM public.customer
                        WHERE customer_id = %s
        """, (customer_id,))

        existence = curr.fetchall()

        if existence:
            session["customer_id"] = customer_id
            return redirect(url_for("view_bookings"))
        
        else:
            return render_template("customer_login.html")

    return render_template("customer_login.html")


@app.route("/walkin")
def walkin():
    return render_template("process_walkins.html")


@app.route("/employee_dashboard")
def employee_dashboard():
    return render_template("employee_dashboard.html")


#EVERYTHING STARTING FROM HERE IS RELATED TO THE MANAGING OF CUSTOMERS

@app.route("/manage_customers")
def manage_customers():
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)


    cur.execute("SELECT c.customer_id, " \
    " c.first_name," \
    " c.city, " \
    " c.province, " \
    " c.type_of_id, " \
    " c.id_value, " \
    " c.date_of_registration "
    " FROM public.customer c "
    "ORDER BY c.customer_id""")

    customers = cur.fetchall()

    edit_id = request.args.get("edit")
    editing = None

    if edit_id:
        cur.execute("""
            SELECT customer_id, first_name, middle_name, last_name,
                   street_number, street_name, apt_number,
                   city, province, zip,
                   type_of_id, id_value, date_of_registration
            FROM public.customer
            WHERE customer_id = %s
        """, (edit_id,))
        editing = cur.fetchone()


    cur.close()
    conn.close()

    return render_template("manage_customers.html", customers = customers, editing = editing)
        


@app.route("/manage/customers/delete/<int:cid>", methods = ["POST"])
def delete_customers(cid):
    conn = get_db_connection()
    curr = conn.cursor()

    curr.execute(""" DELETE FROM 
                 public.customer c
                 WHERE c.customer_id = %s

    """, (cid,))

    conn.commit()
    curr.close()
    conn.close()

    return redirect(url_for("manage_customers"))


@app.route("/add_customer", methods = ["POST"])
def add_customer():
    first_name = request.form["first_name"]
    middle_name = request.form["middle_name"]
    last_name = request.form["last_name"]

    street_number = request.form["street_number"]
    street_name = request.form["street_name"]
    apt_number = request.form["apt_number"]

    city = request.form["city"]
    province = request.form["province"]
    zip = request.form["zip"]

    type_of_id = request.form["type_of_id"]
    id_value = request.form["id_value"]
    date_of_registration = request.form["date_of_registration"]


    conn = get_db_connection()
    curr = conn.cursor()

    curr.execute("""SELECT 
                 setval('customer_customer_id_seq', (SELECT MAX(customer_id) 
                 FROM public.customer));""")

    curr.execute("""
        INSERT INTO public.customer (
            first_name, middle_name, last_name,
            street_number, street_name, apt_number,
            city, province, zip,
            type_of_id, id_value, date_of_registration
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (
        first_name, middle_name, last_name,
        street_number, street_name, apt_number if apt_number else None,
        city, province, zip,
        type_of_id, id_value, date_of_registration
    ))

    conn.commit()
    curr.close()
    conn.close()


    return redirect(url_for("manage_customers"))


@app.route("/edit_customer/<int:cid>", methods = ["POST"])
def edit_customer(cid):
    first_name = request.form["first_name"]
    middle_name = request.form["middle_name"]
    last_name = request.form["last_name"]

    street_number = request.form["street_number"]
    street_name = request.form["street_name"]
    apt_number = request.form["apt_number"]

    city = request.form["city"]
    province = request.form["province"]
    zip = request.form["zip"]

    type_of_id = request.form["type_of_id"]
    id_value = request.form["id_value"]

    conn = get_db_connection()
    curr = conn.cursor()

    curr.execute("""UPDATE public.customer 
                SET first_name = %s,
                middle_name = %s,
                last_name = %s,
                street_number = %s,
                street_name = %s,
                apt_number = %s,
                city = %s,
                province = %s,
                zip = %s,
                type_of_id = %s,
                id_value = %s
                WHERE customer_id = %s
                 """, (        first_name, middle_name if middle_name else None, last_name,
        street_number, street_name, apt_number if apt_number else None,
        city, province, zip, type_of_id, id_value, cid))
    
    conn.commit()

    curr.close()
    conn.close()

    return redirect(url_for("manage_customers"))





@app.route("/manage_employees")
def manage_employees():
    return render_template("manage_employees.html")


@app.route("/manage_hotels")
def manage_hotels():
    return render_template("manage_hotels.html")


@app.route("/manage_rooms")
def manage_rooms():
    return render_template("manage_rooms.html")



if __name__ == "__main__":
    app.run(debug=True)