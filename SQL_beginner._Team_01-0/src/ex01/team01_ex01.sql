-- insert into currency values (100, 'EUR', 0.85, '2022-01-01 13:29');
-- insert into currency values (100, 'EUR', 0.79, '2022-01-08 13:29');

WITH full_balance_new AS(
WITH balance_new AS
	(SELECT user_id,
		    coalesce("user".name, 'not defined') AS name,
	        coalesce("user".lastname, 'not defined') AS lastname,
	        type,
	        bal1.sum AS volume,
	        bal1.currency_id,
	        bal1.updated
	FROM
		(SELECT user_id,
		 sum(money) AS sum,
		 type,
		 currency_id,
		 updated
		FROM balance
		GROUP BY  user_id, type, currency_id, updated
		ORDER BY  1) AS bal1 FULL
		JOIN "user"
			ON id = bal1.user_id), t1 AS
			(SELECT balance_new.user_id,
		 balance_new.name AS user_name,
		 balance_new.lastname,
		 type,
		 volume,
		 currency_id,
		 balance_new.updated AS balance_updated,
		 currency.name AS currency_name,
		 rate_to_usd,
		 currency.updated AS currency_updated,

				CASE
				WHEN balance_new.updated <= currency.updated THEN
				(currency.updated - balance_new.updated)
				ELSE (balance_new.updated - currency.updated)
				END AS date_diff
			FROM balance_new FULL
			JOIN currency
				ON currency_id = currency.id
			ORDER BY  1, 5)
			SELECT t1.user_id,
		 t1.user_name,
		 t1.lastname,
		 t1.type,
		 t1.volume,
		 t1.currency_id,
		 t1.balance_updated,
		 t1.currency_updated,
		 MIN(date_diff)
				OVER (PARTITION BY t1.user_id, t1.type, t1.balance_updated) AS min
			FROM t1), dist_balance_new AS
			(SELECT user_id,
		 user_name,
		 lastname,
		 type,
		 volume,
		 currency_id,
		 balance_updated,
		 min
			FROM full_balance_new
			GROUP BY  user_id,user_name, lastname, type, volume, currency_id, balance_updated, min)

SELECT   user_name AS name,
		 lastname,
		 name AS currency_name,
		 volume * currency.rate_to_usd AS currency_in_usd
	FROM dist_balance_new
	    JOIN currency
	ON dist_balance_new.currency_id = currency.id
		AND (dist_balance_new.balance_updated+min) = currency.updated
		OR (dist_balance_new.balance_updated-min) = currency.updated
ORDER BY  1 DESC, 2, 3;
