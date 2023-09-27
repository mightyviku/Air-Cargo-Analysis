create database air_cargo;
use air_cargo;

-- Tables have been imported using the table data import wizard

alter table routes
add constraint flt_num_chk check(flight_num is not null);

alter table routes
add constraint routes_unq unique(route_id);

alter table routes
add constraint distance_chk check(distance_miles>0);

-- Query to display all passengers who travelled from routes 1 to 25
select c.first_name, c.last_name, p.route_id
from passengers_on_flights p
join customer c on p.customer_id = c.customer_id
where route_id >= 1 and route_id <= 25;

-- Query to identify passengers and total revenue from business class tickets
select count(distinct customer_id) as no_of_passengers,
sum(no_of_tickets*Price_per_ticket) as total_revenue
from ticket_details
where class_id = 'Bussiness';

-- Query to get full name of each customer
select first_name, last_name
from customer;

-- Query to extract customers who have registered and booked a ticket
select distinct c.first_name, c.last_name, t.customer_id
from customer c
inner join ticket_details t on c.customer_id = t.customer_id;

-- Query to get customers names who are flying on Emirates
select distinct c.first_name, c.last_name, t.customer_id
from customer c
inner join ticket_details t on c.customer_id = t.customer_id
where brand = 'Emirates';

-- Query to get customers who have flown on Economy Plus class with group by and having
select distinct c.first_name, c.last_name, p.customer_id
from customer c
join passengers_on_flights p on c.customer_id = p.customer_id
where class_id = 'Economy Plus'
group by customer_id having count(*) > 0;

-- Query to determine if total revenue from tickets crossed $10000
select if(sum(no_of_tickets*Price_per_ticket)>10000, 'Yes', 'No')
as rev_crossed_10000,
sum(no_of_tickets*Price_per_ticket) as revenue
from ticket_details;

-- Query to create a new user
create user 'new_user'@'localhost' identified by 'password';
grant select, insert, update, delete on air_cargo.* to 'new_user'@'localhost';

-- Query to determind max ticket price for each class using window functions
select distinct class_id, max(Price_per_ticket) over (partition by class_id)
as max_price_per_class
from ticket_details;

-- Query to show information on passengers the travelled on route 4 with improved speed and performance through indexing
create index idx_route_id on passengers_on_flights(route_id);

select * from passengers_on_flights
where route_id = 4;

-- Query to view the execution plan on the table where route = 4
explain select * from passengers_on_flights
where route_id = 4;

-- Query to show total price spent on tickets by each customer across all aircraft ids with rollup
select customer_id, aircraft_id, sum(Price_per_ticket*no_of_tickets) as total_price
from ticket_details
group by customer_id, aircraft_id with rollup;

-- View which queries customer full names and airline names of all business class flights
create view business_class as
select c.first_name, c.last_name, t.brand
from customer c
join ticket_details t on c.customer_id = t.customer_id
where class_id = 'Bussiness';

select * from business_class;

delimiter //
-- Stored procedure that shows information from passengers_on_flights on routes between the arguments lower_bound and upper_bound
create procedure range_of_routes(
	in lower_bound int,
    in upper_bound int
)
begin
	if not exists (
		select 1 from information_schema.tables
        where table_name = 'passengers_on_flights'
	) then
		signal sqlstate '45000'
        set message_text = 'Table passengers_on_flights does not exist';
	end if;
    
	select * from passengers_on_flights
    where route_id between lower_bound and upper_bound;
end //

call range_of_routes(20,50);
//

-- Stored procedure that shows information on all routes that are longer than 2000 miles
create procedure dist_over_2000()
begin
	select * from routes
    where distance_miles > 2000;
end;
//

call dist_over_2000();
//

-- Stored procedure which groups routes into categories based on the distance of travel: short, intermediate, and long
create procedure distance_groups()
begin
	select distance_miles,
    case
		when distance_miles>=0 and distance_miles<=2000 then 'SDT'
        when distance_miles>2000 and distance_miles<=6000 then 'IDT'
        when distance_miles>600 then 'LDT'
        end as distance_category
	from routes;
end; 
//

call distance_groups();
//

-- Stored procedure which shows purchase date, customer id, and class id, and uses class id to determine if a customer receives complimentary services
create procedure complimentary_services()
begin
	select p_date, customer_id, class_id, 
    case
		when class_id = 'Bussiness' or class_id = 'Economy Plus' then 'Yes'
        else 'No'
	end as comp_service
    from ticket_details;
end;
//

call complimentary_services();
//

-- Query which returns the first customer whose last name ends with Scott
select * from customer
where last_name like '%Scott'
limit 1;