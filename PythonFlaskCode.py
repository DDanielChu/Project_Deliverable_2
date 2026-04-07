from flask import Flask, redirect, url_for, request, render_template, session
import psycopg2
import psycopg2.extras
from datetime import datetime



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

    # conn = psycopg2.connect(
    #     dbname="hotel_db",
    #     user="postgres",
    #     password="20177Wsbwswn0!",
    #     host="localhost",
    #     port="5432"
    # )

    return conn

    


def get_room_information(start_date, end_date, room_capacity, area, hotel_chain, stars, totalRooms, price):
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

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
            r.type_of_view,
            r.extension_of_bed,
            count(r.room_id) OVER (PARTITION BY h.hotel_id) AS total_rooms_in_hotel
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
        conditions.append("hc.chain_id = %s")
        parameters.append(hotel_chain)

    if stars is not None and stars != "":
        conditions.append("h.star_number = %s")
        parameters.append(stars)

    if totalRooms is not None and totalRooms != "":
        conditions.append("total_rooms_in_hotel > %s")
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


@app.route("/set-role", methods=["POST"])
def set_role():
    role = request.form["role"]
    session["role"] = role

    if role == "customer":
        return redirect(url_for("customer_login"))

    else:
        return redirect(url_for("employee_login"))




#THESE ARE FOR THE CUSTOMERS

@app.route("/search", methods = ["GET"])
def search():
    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")
    capacity = request.args.get("capacity")
    max_price = request.args.get("max_price")
    city = request.args.get("city")
    chain_id = request.args.get("chain_id")
    stars = request.args.get("stars")
    min_rooms = request.args.get("min_rooms")


    conn = get_db_connection()
    curr = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    curr.execute("""SELECT h.city, h.province FROM public.hotel h ORDER BY h.city, h.province""")
    cities = curr.fetchall()

    curr.execute("""SELECT ch.chain_id, ch.hotel_name FROM public.hotel_chain ch ORDER BY ch.chain_id""")
    chains = curr.fetchall()

    results = []
    error = None

    if (start_date and end_date):
        start = datetime.strptime(start_date, "%Y-%m-%d")
        end = datetime.strptime(end_date, "%Y-%m-%d")

        if (start < end):
           results = get_room_information(start_date, end_date,capacity, city, chain_id, stars, min_rooms, max_price)
        else:
            error = "Put start date before end date"

    return render_template("search.html", 
                       cities = cities,
                       chains = chains,
                        rooms = results,
                        start_date=start_date,
                        end_date=end_date,
                        capacity=capacity,
                        max_price=max_price,
                        city=city,
                        chain_id=chain_id,
                        stars=stars,
                        min_rooms=min_rooms,
                        error = error
                       )


@app.route("/view_bookings")
def view_bookings():
    customer_id = session["customer_id"]

    conn = get_db_connection()
    curr = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    curr.execute(""" SELECT
                 b.booking_id,
                 h.city,
                 h.province,
                 b.hotel_id,
                 h.star_number,
                 b.room_id,
                 b.start_date,
                 b.end_date,
                 r.price,
                 r.type_of_view,
                 b.status
                 FROM public.booking b
                 JOIN public.room r ON r.room_id = b.room_id AND r.hotel_id = b.hotel_id
                 JOIN public.hotel h ON h.hotel_id = b.hotel_id
                 WHERE b.customer_id = %s           
    """, (customer_id,))

    bookings = curr.fetchall()

    curr.close()
    conn.close()

    return render_template("view_bookings.html", bookings = bookings)


@app.route("/cancel-booking/<int:bid>", methods = ["POST"])
def cancel_booking(bid):
    conn = get_db_connection()
    curr = conn.cursor()

    curr.execute("DELETE FROM public.booking WHERE booking_id = %s", (bid,))

    conn.commit()

    curr.close()
    conn.close()

    return redirect(url_for("view_bookings"))

@app.route("/views")
def views():
    conn = get_db_connection()
    curr = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    curr.execute(""" SELECT * FROM available_rooms_per_area""")

    available = curr.fetchall()

    curr.execute(""" SELECT * FROM hotel_total_capacity""")

    capacity = curr.fetchall()

    return render_template("views.html", available = available, capacity = capacity)


@app.route("/book", methods = ["POST"])
def book():
    conn  = get_db_connection()
    curr = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    customer_id = session["customer_id"]

    hotel_id = request.form["hotel_id"]
    room_id = request.form["room_id"]
    start_date = request.form["start_date"]
    end_date = request.form["end_date"]
    
    curr.execute("""SELECT 
                setval('booking_booking_id_seq', (SELECT MAX(booking_id) 
                FROM public.booking));""")

    curr.execute(""" INSERT INTO public.booking 
                 (customer_id, hotel_id, room_id, start_date, end_date, status)
                VALUES (%s,%s,%s,%s,%s,%s)
        """, (customer_id, hotel_id, room_id, start_date, end_date, 'PENDING'))

    conn.commit()
    
    curr.close()
    conn.close()

    return redirect(url_for("view_bookings"))
    


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

            curr.close()
            conn.close()

            return redirect(url_for("view_bookings"))
        
        else:
            curr.close()
            conn.close()
            return render_template("customer_login.html")
        

    return render_template("customer_login.html")




#NO LONGER FOR CUSTOMER 



@app.route("/walkin", methods = ["GET","POST"])
def walkin():
    conn = get_db_connection()
    curr = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    employee_ssn = session["employee_ssn"]

    curr.execute("""SELECT * FROM public.employee WHERE ssn = %s LIMIT 1""", (employee_ssn,))

    mapOfEmployee = curr.fetchone()


    curr.execute(""" SELECT * FROM public.customer""")

    customers = curr.fetchall()

    curr.execute("""SELECT * FROM public.room WHERE hotel_id = %s""", (mapOfEmployee["hotel_id"],))

    rooms = curr.fetchall()

    error = None

    if request.method == "POST":

        customer_id = request.form["customer_id"]
        room_id = request.form["room_id"]
        start_date = request.form["start_date"]
        end_date = request.form["end_date"]
        payment_method = request.form["payment_method"]
        



        if (customer_id and room_id and start_date and end_date and payment_method):
            
            
            start = datetime.strptime(start_date, "%Y-%m-%d")
            end = datetime.strptime(end_date, "%Y-%m-%d")

            if (start < end):
                results = get_room_information(start_date, end_date,capacity, city, chain_id, stars, min_rooms, max_price)

                curr.execute("""SELECT * FROM public.room r 
                            WHERE room_id = %s AND hotel_id = %s LIMIT 1""", (room_id, mapOfEmployee["hotel_id"]))

                room_being_used = curr.fetchone()

                curr.execute("""SELECT 
                        setval('renting_rent_id_seq', (SELECT MAX(rent_id) 
                        FROM public.renting));""")

                curr.execute("""INSERT INTO public.renting
                            (customer_id, hotel_id, room_id, 
                            employee_ssn, booking_id, start_date, end_date, 
                            price, payment_method, is_walk_in)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                            (customer_id, mapOfEmployee["hotel_id"], room_id, employee_ssn, None, start_date, end_date, room_being_used["price"], payment_method, True))

                conn.commit()
                    
                curr.close()
                conn.close()


                return redirect(url_for("employee_dashboard"))

            else:
                error = "Put start date before end date"



    curr.close()
    conn.close()


    return render_template("process_walkins.html", customers = customers, rooms = rooms, error = error)


@app.route("/employee_login", methods = ["GET", "POST"])
def employee_login():
    if request.method == "POST":
        conn = get_db_connection()
        curr = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        employee_ssn = request.form["ssn"]

        curr.execute(""" SELECT ssn, hotel_id, first_name 
                    FROM public.employee
                    WHERE ssn = %s
        """, (employee_ssn,))

        existence = curr.fetchone()

        if existence:
            session["employee_ssn"] = employee_ssn
            session["hotel_id"] = existence["hotel_id"]
            session["first_name"] = existence["first_name"]

            curr.close()
            conn.close()

            return redirect(url_for("employee_dashboard"))
        
        else:
            
            curr.close()
            conn.close()
            return render_template("employee_login.html")

    
    return render_template("employee_login.html")



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