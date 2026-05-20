By The Way we gonna use SIEGE for this test and we gonna talk about each request it's input and output, of course also we gonna set the server that we use on this tests:


# Device Server Characteristics

# Component   	 Value

  CPU	         ntel Core™ i7
  RAM	         15 GB
  Disk           163 GB
  OS	         Linux
  Backend	     Spring Boot
  Database	     PostgreSQL
  Environment	 Local machine


# Endpoint Tested

#           Service   	                    Endpoint        	                  Method

1/      Authentication Service	          /api/auth/login                           POST

2/      User Management Service	          /api/users/me                             Get

3/      Play List Music Service	          /api/playlists                            POST




# Test That We Use On The Example

1/          siege -c50 -t30S \
-H 'Content-Type: application/json' \
'http://localhost:8080/api/auth/login POST {"email":"fantiaboubaker@gmail.com","password":"Password_here"}'


2/          siege -c50 -t30S \
-H "Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJmYW50aWFib3ViYWtlckBnbWFpbC5jb20iLCJ1c2VySWQiOiJlYTUzMWQ4My1kNDQ0LTQ5NjYtYjFhYS0zMmRkZDY4ZTg0ZGYiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzc5Mjg2NjM5LCJleHAiOjE3Nzk4OTE0Mzl9.z2Sq9w-05VdJGnOrJJFDaW5BoRsGp-Wa-ic61s-sJOecUbDfcsg9CgZKWEhHBAKHPK-2ATRhAakP5MBMJkRAsw " \
http://localhost:8080/api/users/me


3/          siege -c30 -t30S \
-H 'Content-Type: application/json' \
-H "Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJmYW50aWFib3ViYWtlckBnbWFpbC5jb20iLCJ1c2VySWQiOiJlYTUzMWQ4My1kNDQ0LTQ5NjYtYjFhYS0zMmRkZDY4ZTg0ZGYiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzc5Mjg2NjM5LCJleHAiOjE3Nzk4OTE0Mzl9.z2Sq9w-05VdJGnOrJJFDaW5BoRsGp-Wa-ic61s-sJOecUbDfcsg9CgZKWEhHBAKHPK-2ATRhAakP5MBMJkRAsw" \
'http://localhost:8080/api/playlists POST {"name":"My Playlist","description":"Load testing playlist creation","visibility":"public","licenseType":"open"}'




#                        Result Of Each Endpoint 


# Result Of The Test N 1:          

Transactions:		            5742    hits
Availability:		            100.00 %
Elapsed time:		            30.57 secs
Data transferred:	            0.98 MB
Response time:		            264.80 ms
Transaction rate:	            187.83 trans/sec
Throughput:		                0.03 MB/sec
Concurrency:		            49.74
Successful transactions:        1
Failed transactions:	        0
Longest transaction:	        490.00 ms
Shortest transaction:	        80.00 ms


# Result Of The Test N 2:

Transactions:		            223215    hits
Availability:		            100.00 %
Elapsed time:		            30.69 secs
Data transferred:	            42.36 MB
Response time:		            6.75 ms
Transaction rate:	            7273.22 trans/sec
Throughput:		                1.38 MB/sec
Concurrency:		            49.07
Successful transactions:        223216
Failed transactions:	        0
Longest transaction:	        60.00 ms
Shortest transaction:	        0.00 ms


# Result Of The Test N 3:          

Transactions:		            123949    hits
Availability:		            100.00 %
Elapsed time:		            30.55 secs
Data transferred:	            44.54 MB
Response time:		            7.29 ms
Transaction rate:	            4057.25 trans/sec
Throughput:		                1.46 MB/sec
Concurrency:		            29.58
Successful transactions:        123949
Failed transactions:	        0
Longest transaction:	        40.00 ms
Shortest transaction:	        0.00 ms
