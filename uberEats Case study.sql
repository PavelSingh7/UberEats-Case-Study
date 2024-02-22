SELECT * FROM [users ];
SELECT * FROM [orders ];
SELECT * FROM [order_details ];
SELECT * FROM restaurants;
SELECT * FROM food;
SELECT * FROM menu;
SELECT * FROM delivery_partner;

--UberEats case study
--1)Find customers who never ordered
SELECT users.user_id, users.name
FROM users 
LEFT JOIN orders  ON users.user_id = orders.user_id
WHERE orders.user_id IS NULL;

-- OR 
SELECT name FROM users 
WHERE user_id NOT IN (SELECT user_id FROM orders)

--2)Average price per dish

SELECT food.f_name,AVG(menu.price) AS 'Average_price'
FROM food
JOIN menu
ON food.f_id=menu.f_id
GROUP BY food.f_name

--3)Find top restaurant in terms of numbers of orders for given month
SELECT TOP 1 restaurants.r_name, COUNT(orders.order_id) as 'Number_of_orders'
FROM restaurants
JOIN orders
ON restaurants.r_id = orders.r_id
WHERE MONTH(orders.date) = 6 --Suppose we need top restaurants for June
GROUP BY restaurants.r_name
ORDER BY Number_of_orders DESC;
--OFFSET 0 ROW FETCH NEXT 1 ROW ONLY(We can also use offset to find top 1 or 2 or 3 restaurants)


--4)Find restuarants with monthly sales > x

SELECT restaurants.r_name,MONTH(orders.date) as 'Month',SUM(orders.amount) as 'total_sales'
FROM orders
JOIN restaurants
ON orders.r_id=restaurants.r_id
GROUP BY restaurants.r_name,MONTH(orders.date)
HAVING SUM([orders ].amount)> 900 --let's take amount to be 900
ORDER BY Month,total_sales DESC

--5)Show all orders with order details of a particular customer in a particular date range

WITH t1 AS (SELECT o.order_id as 'o_id',r.r_name as 'restaurant'
			FROM orders o
			JOIN restaurants r
			ON o.r_id = r.r_id
			WHERE user_id = (SELECT user_id FROM users WHERE user_id = 4) 
			AND date > '2022-06-10' AND date < '2022-07-10'),
 t2 AS (SELECT o1.order_id as 'o_id',f.f_name
        FROM order_details o1
		JOIN food f
		ON o1.f_id = f.f_id)
SELECT t1.o_id,t1.restaurant, t2.f_name 
FROM t1
JOIN t2
ON t1.o_id=t2.o_id


--6)Find restaurants with Max repeated customers

WITH t1 AS (SELECT user_id,r_id,
        ROW_NUMBER() OVER (PARTITION BY r_id, user_id ORDER BY (SELECT NULL)) AS count
    FROM  orders),
t2 AS (SELECT t1.r_id,t1.count
	FROM  t1
	WHERE t1.count = (SELECT MAX(count)
                  FROM t1))
SELECT r.r_name,COUNT(t2.count) as 'visits'
FROM restaurants r
JOIN t2
ON r.r_id=t2.r_id
GROUP BY r.r_name
HAVING COUNT(t2.count)>1

--7)Find most loyal customers of all restaurants
--(We need to find customer who ordered most from a restaurant

WITH t1 AS (SELECT r_id,user_id,COUNT(order_id) AS 'total_orders',
DENSE_RANK() OVER(PARTITION BY r_id ORDER BY (COUNT(order_id)) DESC) as 'row'
FROM [orders ]
GROUP BY r_id,user_id),
t2 AS (SELECT * FROM t1
		WHERE row=1)
SELECT [users ].name,restaurants.r_name,t2.total_orders
FROM t2 
JOIN [users ]
ON t2.user_id=users.user_id
JOIN restaurants
ON t2.r_id=restaurants.r_id;

--8)Month over month growth of zomato 
--FORMULA IS current_month - last_month/last_month *100

WITH t1 AS (SELECT MONTH(date) AS 'Month',SUM(amount) AS 'Revenue',
			LAG(SUM(amount))OVER( ORDER BY (MONTH(date))) AS 'prev_rev',
			SUM(amount)-LAG(SUM(amount))OVER( ORDER BY (MONTH(date))) AS 'difference'
			FROM [orders ]
			GROUP BY MONTH(date))
SELECT Month,(difference * 100.0) /prev_rev AS 'Percentage_growth'
FROM t1;

--9)Month over month growth for a particular restraurant

WITH t1 AS( SELECT MONTH(o.date) AS 'month',SUM(o.amount) as 'revenue',
			LAG(SUM(o.amount))OVER( ORDER BY SUM(o.amount)) AS 'prev_rev',
			SUM(o.amount)-LAG(SUM(o.amount))OVER(ORDER BY SUM(o.amount)) AS 'difference'
			FROM restaurants r
			JOIN orders o
			ON r.r_id=o.r_id
			WHERE r.r_name LIKE 'kfc' -- let's take KFC 
			GROUP BY r.r_name,MONTH(o.date))
SELECT month, (CAST(difference AS decimal(5,2))*100/prev_rev) AS 'Percentage_growth_KFC'
FROM t1;

--10)Every customer favourite food
WITH t1 AS (SELECT u.name AS 'Name',od.f_id AS 'f_id'
			FROM [orders ] o
			JOIN [users ] u
			ON o.user_id=u.user_id
			JOIN [order_details ] od
			ON o.order_id=od.order_id),
t2 AS (SELECT t1.Name,f.f_name
		FROM t1
		JOIN food f
		ON t1.f_id=f.f_id),
t3 AS (SELECT *, COUNT(f_name) AS 'times_ordered',
DENSE_RANK()OVER(PARTITION BY Name ORDER BY COUNT(f_name) DESC) AS 'Rank'
FROM t2
GROUP BY Name,f_name)
SELECT Name,f_name AS 'Favourite_food', times_ordered
FROM t3
WHERE Rank =1





