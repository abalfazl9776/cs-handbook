Syntax:

sql
DECIMAL(p, s)
p (precision): Total number of digits (1-38). Default is 18.

s (scale): Number of digits after the decimal point (0 ≤ s ≤ p). Default is 0.

Storage Size:

Depends on precision (p):

1-9 digits: 5 bytes

10-19 digits: 9 bytes

20-28 digits: 13 bytes

29-38 digits: 17 bytes