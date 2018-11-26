# OpenLocationCode-TransactSQL
TransactSQL function for generating an Open Location Code (AKA Google Plus Code) based on the Latitude and Longitude pairs that you have in your database.

For the original code, see https://github.com/google/open-location-code

For more information about Plus Codes see https://plus.codes/

# Usage

After creating the stored procedure in the database and adding a new column PlusCode to my table, I ran the following query to fill in the values:

```SQL
UPDATE Addresses
SET PlusCode = dbo.GetOpenLocationCode(Latitude, Longitude, default)
WHERE PlusCode is null
```
