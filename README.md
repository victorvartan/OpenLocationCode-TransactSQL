# OpenLocationCode-TransactSQL
TransactSQL function for encoding an Open Location Code (AKA Google Plus Code) from a Latitude and Longitude pair that you have in your database.

For the original code, see https://github.com/google/open-location-code

For more information about Plus Codes see https://plus.codes/

# Usage

After creating the function in the database and adding a new column PlusCode to my table, I ran the following query to fill in the values:

```SQL
UPDATE Addresses
SET PlusCode = dbo.GetOpenLocationCode(Latitude, Longitude, default)
WHERE PlusCode is null
```

# Tests

```SQL
select dbo.GetOpenLocationCode(40.6892474, -74.0445405, default) -- Statue of liberty, expected result: 87G7MXQ4+M5
select dbo.GetOpenLocationCode(48.858260200000004, 2.2944990543196795, default) -- Eiffel Tower, expected result: 8FW4V75V+8Q
```
