
CREATE TABLE `Amazon sales 2025`.`amazon_products_sales_data_uncleaned` (
  `title` TEXT,
  `rating` TEXT,
  `number_of_reviews` TEXT,
  `bought_in_last_month` TEXT,
  `current/discounted_price` TEXT,
  `price_on_variant` TEXT,
  `listed_price` TEXT,
  `is_best_seller` TEXT,
  `is_sponsored` TEXT,
  `is_couponed` TEXT,
  `buy_box_availability` TEXT,
  `delivery_details` TEXT,
  `sustainability_badges` TEXT,
  `image_url` TEXT,
  `product_url` TEXT,
  `collected_at` TEXT
); 

DESCRIBE `Amazon sales 2025`.`amazon_products_sales_data_uncleaned`;

LOAD DATA LOCAL INFILE '/Users/suryadevrathjayakumar/Documents/amazon_products_sales_data_uncleaned.csv'
INTO TABLE `Amazon sales 2025`.`amazon_products_sales_data_uncleaned`
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT title, product_url, collected_at) AS distinct_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_uncleaned`;


SELECT title, product_url, collected_at, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_uncleaned`
GROUP BY title, product_url, collected_at
HAVING COUNT(*) > 1
ORDER BY cnt DESC
LIMIT 10;

SELECT *
FROM `Amazon sales 2025`.`amazon_products_sales_data_uncleaned`
WHERE title = 'CR 2016 MAXELL LITHIUM BATTERIES (2 piece) 3V Watch 2016 New'
LIMIT 100;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT title, rating, number_of_reviews, bought_in_last_month,
             `current/discounted_price`, price_on_variant, listed_price,
             is_best_seller, is_sponsored, is_couponed, buy_box_availability,
             delivery_details, sustainability_badges, image_url, product_url,
             collected_at) AS distinct_full_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_uncleaned`;

CREATE TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned` AS
SELECT DISTINCT *
FROM `Amazon sales 2025`.`amazon_products_sales_data_uncleaned`;

SELECT COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN rating_clean DECIMAL(3,2);

SET SQL_SAFE_UPDATES = 0;

SELECT rating, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE rating IS NULL
   OR TRIM(rating) = ''
   OR NOT (rating REGEXP '^[0-9]+(\\.[0-9]+)?')
GROUP BY rating
ORDER BY cnt DESC
LIMIT 30;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET rating_clean = CASE
  WHEN rating REGEXP '^[0-9]+(\\.[0-9]+)?' THEN CAST(SUBSTRING_INDEX(rating, ' ', 1) AS DECIMAL(3,2))
  ELSE NULL
END;

SELECT COUNT(*) AS null_rating_clean
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE rating_clean IS NULL;

SELECT number_of_reviews, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE number_of_reviews IS NULL
   OR TRIM(number_of_reviews) = ''
   OR NOT (REPLACE(number_of_reviews, ',', '') REGEXP '^[0-9]+$')
GROUP BY number_of_reviews
ORDER BY cnt DESC
LIMIT 30;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN reviews_clean INT;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET reviews_clean = CASE
  WHEN REPLACE(number_of_reviews, ',', '') REGEXP '^[0-9]+$'
    THEN CAST(REPLACE(number_of_reviews, ',', '') AS UNSIGNED)
  ELSE NULL
END;

SELECT number_of_reviews, reviews_clean
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
LIMIT 20;

SELECT COUNT(*) AS null_reviews_clean
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE reviews_clean IS NULL;

SELECT bought_in_last_month, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY bought_in_last_month
ORDER BY cnt DESC
LIMIT 30;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT BINARY CONCAT_WS('|', title, rating, number_of_reviews, bought_in_last_month,
             `current/discounted_price`, price_on_variant, listed_price,
             is_best_seller, is_sponsored, is_couponed, buy_box_availability,
             delivery_details, sustainability_badges, image_url, product_url,
             collected_at)) AS distinct_rows_exact
FROM `Amazon sales 2025`.`amazon_products_sales_data_uncleaned`;

SET SQL_SAFE_UPDATES = 0;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN bought_last_month_clean INT;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET bought_last_month_clean = CASE
  WHEN bought_in_last_month REGEXP '^[0-9]+K\\+ bought in past month'
    THEN CAST(REGEXP_SUBSTR(bought_in_last_month, '^[0-9]+') AS UNSIGNED) * 1000
  WHEN bought_in_last_month REGEXP '^[0-9]+\\+ bought in past month'
    THEN CAST(REGEXP_SUBSTR(bought_in_last_month, '^[0-9]+') AS UNSIGNED)
  ELSE NULL
END;

SELECT COUNT(*) AS null_bought_clean
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE bought_last_month_clean IS NULL;

SELECT bought_in_last_month, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE bought_last_month_clean IS NULL
GROUP BY bought_in_last_month
ORDER BY cnt DESC
LIMIT 40;

SELECT
  SUM(`current/discounted_price` IS NULL OR TRIM(`current/discounted_price`) = '') AS blank_count,
  SUM(`current/discounted_price` IS NOT NULL AND TRIM(`current/discounted_price`) <> ''
      AND NOT (`current/discounted_price` REGEXP '^[0-9,]+(\\.[0-9]+)?$')) AS non_numeric_count,
  COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN current_price_clean DECIMAL(10,2);

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET current_price_clean = CASE
  WHEN `current/discounted_price` IS NULL OR TRIM(`current/discounted_price`) = '' THEN NULL
  ELSE CAST(REPLACE(REPLACE(`current/discounted_price`, '$', ''), ',', '') AS DECIMAL(10,2))
END;

SELECT COUNT(*) AS null_current_price
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE current_price_clean IS NULL;

SELECT
  SUM(price_on_variant IS NULL OR TRIM(price_on_variant) = '') AS blank_count,
  SUM(price_on_variant IS NOT NULL AND TRIM(price_on_variant) <> ''
      AND TRIM(REPLACE(price_on_variant, 'basic variant price: ', '')) REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$') AS valid_price_count,
  SUM(price_on_variant IS NOT NULL AND TRIM(price_on_variant) <> ''
      AND NOT (TRIM(REPLACE(price_on_variant, 'basic variant price: ', '')) REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$')) AS garbage_count,
  COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

SELECT
  SUM(current_price_clean IS NULL
      AND TRIM(REPLACE(price_on_variant, 'basic variant price: ', '')) REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$') AS fillable_from_variant,
  SUM(current_price_clean IS NULL
      AND NOT (TRIM(REPLACE(price_on_variant, 'basic variant price: ', '')) REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$')) AS still_missing_after_fallback,
  SUM(current_price_clean IS NULL) AS total_missing_current_price
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN variant_price_clean DECIMAL(10,2);

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET variant_price_clean = CASE
  WHEN TRIM(REPLACE(price_on_variant, 'basic variant price: ', '')) REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$'
    THEN CAST(REPLACE(REPLACE(TRIM(REPLACE(price_on_variant, 'basic variant price: ', '')), '$', ''), ',', '') AS DECIMAL(10,2))
  ELSE NULL
END;


UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET current_price_clean = COALESCE(current_price_clean, variant_price_clean);

SELECT COUNT(*) AS null_current_price_after_fallback
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE current_price_clean IS NULL;

SELECT
  SUM(listed_price = 'No Discount') AS no_discount_count,
  SUM(listed_price IS NULL OR TRIM(listed_price) = '') AS blank_count,
  SUM(listed_price <> 'No Discount' AND listed_price IS NOT NULL AND TRIM(listed_price) <> ''
      AND NOT (listed_price REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$')) AS unexpected_format_count,
  SUM(listed_price REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$') AS valid_dollar_count,
  COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

	SELECT CONCAT('[', listed_price, ']') AS bracketed_value, LENGTH(listed_price) AS byte_length
	FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
	WHERE listed_price <> 'No Discount'
	  AND listed_price IS NOT NULL AND TRIM(listed_price) <> ''
	LIMIT 20;
    
SELECT
  SUM(TRIM(listed_price) = 'No Discount') AS no_discount_count,
  SUM(listed_price IS NULL OR TRIM(listed_price) = '') AS blank_count,
  SUM(TRIM(listed_price) <> 'No Discount' AND listed_price IS NOT NULL AND TRIM(listed_price) <> ''
      AND NOT (TRIM(listed_price) REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$')) AS unexpected_format_count,
  SUM(TRIM(listed_price) REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$') AS valid_dollar_count,
  COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN listed_price_clean DECIMAL(10,2);

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET listed_price_clean = CASE
  WHEN TRIM(listed_price) = 'No Discount' THEN NULL
  WHEN TRIM(listed_price) REGEXP '^\\$[0-9,]+(\\.[0-9]+)?$'
    THEN CAST(REPLACE(REPLACE(TRIM(listed_price), '$', ''), ',', '') AS DECIMAL(10,2))
  ELSE NULL
END;

SELECT COUNT(*) AS null_listed_price
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE listed_price_clean IS NULL;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET listed_price_clean = COALESCE(listed_price_clean, current_price_clean);

SELECT COUNT(*) AS null_listed_price_final
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE listed_price_clean IS NULL;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN discount_percentage DECIMAL(5,2);

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET discount_percentage = CASE
  WHEN listed_price_clean IS NOT NULL AND listed_price_clean > 0 AND current_price_clean IS NOT NULL
    THEN ROUND((listed_price_clean - current_price_clean) / listed_price_clean * 100, 2)
  ELSE NULL
END;

SELECT
  COUNT(*) AS total_rows,
  SUM(discount_percentage IS NULL) AS null_discount,
  SUM(discount_percentage < 0) AS negative_discount_count,
  MIN(discount_percentage) AS min_discount,
  MAX(discount_percentage) AS max_discount,
  ROUND(AVG(discount_percentage), 2) AS avg_discount
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

SELECT is_best_seller, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY is_best_seller
ORDER BY cnt DESC;

SELECT is_sponsored, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY is_sponsored
ORDER BY cnt DESC;

SELECT is_couponed, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY is_couponed
ORDER BY cnt DESC
LIMIT 20;

SELECT buy_box_availability, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY buy_box_availability
ORDER BY cnt DESC
LIMIT 20;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN is_best_seller_flag TINYINT,
ADD COLUMN is_sponsored_flag TINYINT,
ADD COLUMN buy_box_available TINYINT;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET is_best_seller_flag = CASE WHEN TRIM(is_best_seller) = 'Best Seller' THEN 1 ELSE 0 END,
    is_sponsored_flag = CASE WHEN TRIM(is_sponsored) = 'Sponsored' THEN 1 ELSE 0 END,
    buy_box_available = CASE WHEN buy_box_availability IS NULL OR TRIM(buy_box_availability) = '' THEN 0 ELSE 1 END;

SELECT
  SUM(is_best_seller_flag) AS best_seller_count,
  SUM(is_sponsored_flag) AS sponsored_count,
  SUM(buy_box_available) AS buy_box_count,
  COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN has_coupon TINYINT,
ADD COLUMN coupon_amount DECIMAL(10,2),
ADD COLUMN coupon_type VARCHAR(10);

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET has_coupon = CASE WHEN TRIM(is_couponed) LIKE 'Save %' THEN 1 ELSE 0 END,
    coupon_type = CASE
      WHEN TRIM(is_couponed) REGEXP '^Save \\$[0-9,]+(\\.[0-9]+)? with coupon$' THEN 'dollar'
      WHEN TRIM(is_couponed) REGEXP '^Save [0-9]+% with coupon$' THEN 'percent'
      ELSE NULL
    END,
    coupon_amount = CASE
      WHEN TRIM(is_couponed) REGEXP '^Save \\$[0-9,]+(\\.[0-9]+)? with coupon$'
        THEN CAST(REPLACE(REPLACE(REGEXP_SUBSTR(TRIM(is_couponed), '\\$[0-9,]+(\\.[0-9]+)?'), '$', ''), ',', '') AS DECIMAL(10,2))
      WHEN TRIM(is_couponed) REGEXP '^Save [0-9]+% with coupon$'
        THEN CAST(REGEXP_SUBSTR(TRIM(is_couponed), '[0-9]+') AS DECIMAL(10,2))
      ELSE NULL
    END;
    
SELECT
  SUM(has_coupon) AS coupon_count,
  SUM(coupon_type = 'dollar') AS dollar_type_count,
  SUM(coupon_type = 'percent') AS percent_type_count,
  SUM(has_coupon = 1 AND coupon_amount IS NULL) AS unparsed_coupon_count,
  COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

SELECT CONCAT('[', is_couponed, ']') AS bracketed_value, LENGTH(is_couponed) AS byte_length
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE TRIM(is_couponed) LIKE 'Save %'
LIMIT 15;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET has_coupon = CASE WHEN TRIM(is_couponed) LIKE 'Save %' THEN 1 ELSE 0 END,
    coupon_type = CASE
      WHEN TRIM(is_couponed) REGEXP '^Save \\$[0-9,]+(\\.[0-9]+)?\\s+with coupon$' THEN 'dollar'
      WHEN TRIM(is_couponed) REGEXP '^Save [0-9]+%\\s+with coupon$' THEN 'percent'
      ELSE NULL
    END,
    coupon_amount = CASE
      WHEN TRIM(is_couponed) REGEXP '^Save \\$[0-9,]+(\\.[0-9]+)?\\s+with coupon$'
        THEN CAST(REPLACE(REPLACE(REGEXP_SUBSTR(TRIM(is_couponed), '\\$[0-9,]+(\\.[0-9]+)?'), '$', ''), ',', '') AS DECIMAL(10,2))
      WHEN TRIM(is_couponed) REGEXP '^Save [0-9]+%\\s+with coupon$'
        THEN CAST(REGEXP_SUBSTR(TRIM(is_couponed), '[0-9]+') AS DECIMAL(10,2))
      ELSE NULL
    END;
    
SELECT
  SUM(has_coupon) AS coupon_count,
  SUM(coupon_type = 'dollar') AS dollar_type_count,
  SUM(coupon_type = 'percent') AS percent_type_count,
  SUM(has_coupon = 1 AND coupon_amount IS NULL) AS unparsed_coupon_count,
  COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

SELECT is_couponed, LENGTH(is_couponed) AS byte_length
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE TRIM(is_couponed) LIKE 'Save %'
  AND coupon_amount IS NULL;
  
UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET has_coupon = CASE WHEN TRIM(is_couponed) LIKE 'Save %' THEN 1 ELSE 0 END,
    coupon_type = CASE
      WHEN TRIM(is_couponed) REGEXP '^Save \\$[0-9,]+(\\.[0-9]+)?\\s+with coupon' THEN 'dollar'
      WHEN TRIM(is_couponed) REGEXP '^Save [0-9]+%\\s+with coupon' THEN 'percent'
      ELSE NULL
    END,
    coupon_amount = CASE
      WHEN TRIM(is_couponed) REGEXP '^Save \\$[0-9,]+(\\.[0-9]+)?\\s+with coupon'
        THEN CAST(REPLACE(REPLACE(REGEXP_SUBSTR(TRIM(is_couponed), '\\$[0-9,]+(\\.[0-9]+)?'), '$', ''), ',', '') AS DECIMAL(10,2))
      WHEN TRIM(is_couponed) REGEXP '^Save [0-9]+%\\s+with coupon'
        THEN CAST(REGEXP_SUBSTR(TRIM(is_couponed), '[0-9]+') AS DECIMAL(10,2))
      ELSE NULL
    END;
    
SELECT
  SUM(has_coupon) AS coupon_count,
  SUM(coupon_type = 'dollar') AS dollar_type_count,
  SUM(coupon_type = 'percent') AS percent_type_count,
  SUM(has_coupon = 1 AND coupon_amount IS NULL) AS unparsed_coupon_count,
  COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

SELECT collected_at, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY collected_at
ORDER BY cnt DESC
LIMIT 20;

SELECT collected_at, LENGTH(collected_at) AS byte_length, CONCAT('[', collected_at, ']') AS bracketed
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
LIMIT 20;

SELECT
  collected_at,
  LENGTH(collected_at) AS byte_length,
  RIGHT(collected_at, 6) AS last_6_chars,
  HEX(RIGHT(collected_at, 3)) AS last_3_chars_hex
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
LIMIT 10;

SELECT LENGTH(TRIM(TRAILING '\r' FROM collected_at)) AS clean_length, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY clean_length
ORDER BY cnt DESC;

SELECT MIN(TRIM(TRAILING '\r' FROM collected_at)) AS sample_value,
       LENGTH(TRIM(TRAILING '\r' FROM collected_at)) AS clean_length
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY clean_length
ORDER BY clean_length;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN collected_at_clean DATETIME;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET collected_at_clean = STR_TO_DATE(TRIM(TRAILING '\r' FROM collected_at), '%Y-%m-%d %k:%i');

SELECT
  COUNT(*) AS total_rows,
  SUM(collected_at_clean IS NULL) AS unparsed_count,
  MIN(collected_at_clean) AS earliest,
  MAX(collected_at_clean) AS latest
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

SELECT
  LENGTH(delivery_details) AS len,
  HEX(RIGHT(delivery_details, 2)) AS last_2_hex,
  COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE delivery_details IS NOT NULL AND TRIM(delivery_details) <> ''
GROUP BY len, last_2_hex
ORDER BY cnt DESC
LIMIT 20;

SELECT delivery_details, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY delivery_details
ORDER BY cnt DESC
LIMIT 40;

SELECT delivery_details, LENGTH(delivery_details) AS len
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE LENGTH(delivery_details) > 40
LIMIT 15;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN delivery_date_clean DATE;

SELECT
  delivery_details,
  REGEXP_SUBSTR(delivery_details, '[A-Za-z]{3} [0-9]{1,2}') AS extracted_token,
  CONCAT(REGEXP_SUBSTR(delivery_details, '[A-Za-z]{3} [0-9]{1,2}'), ' ', YEAR(collected_at_clean)) AS full_string_attempted,
  STR_TO_DATE(CONCAT(REGEXP_SUBSTR(delivery_details, '[A-Za-z]{3} [0-9]{1,2}'), ' ', YEAR(collected_at_clean)), '%b %e %Y') AS parsed_result
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE delivery_details IS NOT NULL AND TRIM(delivery_details) <> ''
  AND REGEXP_SUBSTR(delivery_details, '[A-Za-z]{3} [0-9]{1,2}') IS NOT NULL
  AND STR_TO_DATE(CONCAT(REGEXP_SUBSTR(delivery_details, '[A-Za-z]{3} [0-9]{1,2}'), ' ', YEAR(collected_at_clean)), '%b %e %Y') IS NULL
LIMIT 20;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET delivery_date_clean = STR_TO_DATE(
  CONCAT(REGEXP_SUBSTR(delivery_details, '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{1,2}'), ' ', YEAR(collected_at_clean)),
  '%b %e %Y'
);

SELECT
  COUNT(*) AS total_rows,
  SUM(delivery_details IS NULL OR TRIM(delivery_details) = '') AS blank_raw,
  SUM(delivery_date_clean IS NULL AND delivery_details IS NOT NULL AND TRIM(delivery_details) <> '') AS unparsed_nonblank,
  MIN(delivery_date_clean) AS earliest_delivery,
  MAX(delivery_date_clean) AS latest_delivery
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

SELECT
  SUM(product_url IS NULL OR TRIM(product_url) = '') AS blank_url,
  SUM(product_url LIKE '/sspa/click%') AS sponsored_link_count,
  SUM(product_url LIKE 'http%') AS already_full_url_count,
  COUNT(*) AS total_rows
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
MODIFY COLUMN product_url_clean VARCHAR(2000);

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET product_url_clean = CASE
  WHEN product_url IS NULL OR TRIM(product_url) = '' THEN NULL
  ELSE CONCAT('https://www.amazon.com', product_url)
END;

SELECT MAX(LENGTH(product_url)) AS longest_url
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
MODIFY COLUMN product_url_clean VARCHAR(2000);

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET product_url_clean = CASE
  WHEN product_url IS NULL OR TRIM(product_url) = '' THEN NULL
  ELSE CONCAT('https://www.amazon.com', product_url)
END;

SELECT
  COUNT(*) AS total_rows,
  SUM(product_url_clean IS NULL) AS null_url_count,
  SUM(product_url_clean LIKE 'https://www.amazon.com/sspa/click%') AS sponsored_prefixed_count,
  SUM(product_url_clean LIKE 'https://www.amazon.com/%' AND product_url_clean NOT LIKE 'https://www.amazon.com/sspa/click%') AS normal_prefixed_count
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`;

ALTER TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
ADD COLUMN category VARCHAR(30);

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET category = CASE
  WHEN LOWER(title) LIKE '%laptop%' OR LOWER(title) LIKE '%notebook%' OR LOWER(title) LIKE '%macbook%' OR LOWER(title) LIKE '%chromebook%' OR LOWER(title) LIKE '%ultrabook%' OR LOWER(title) LIKE '%acer%' OR LOWER(title) LIKE '%asus%' OR LOWER(title) LIKE '%dell%' OR LOWER(title) LIKE '%lenovo%' OR LOWER(title) LIKE '%hp%' OR LOWER(title) LIKE '%core%' OR LOWER(title) LIKE '%intel%' OR LOWER(title) LIKE '%ryzen%' OR LOWER(title) LIKE '%surface%' OR LOWER(title) LIKE '%thinkpad%' OR LOWER(title) LIKE '%ideapad%'
    THEN 'Laptops'
  WHEN LOWER(title) LIKE '%phone%' OR LOWER(title) LIKE '%iphone%' OR LOWER(title) LIKE '%smartphone%' OR LOWER(title) LIKE '%samsung%' OR LOWER(title) LIKE '%android%' OR LOWER(title) LIKE '%galaxy%' OR LOWER(title) LIKE '%pixel%' OR LOWER(title) LIKE '%oneplus%' OR LOWER(title) LIKE '%xiaomi%' OR LOWER(title) LIKE '%oppo%' OR LOWER(title) LIKE '%realme%' OR LOWER(title) LIKE '%huawei%' OR LOWER(title) LIKE '%vivo%' OR LOWER(title) LIKE '%nokia%' OR LOWER(title) LIKE '%motorola%'
    THEN 'Phones'
  WHEN LOWER(title) LIKE '%headphone%' OR LOWER(title) LIKE '%headset%' OR LOWER(title) LIKE '%earphone%' OR LOWER(title) LIKE '%earbuds%' OR LOWER(title) LIKE '%airpods%' OR LOWER(title) LIKE '%beats%' OR LOWER(title) LIKE '%sony wh%' OR LOWER(title) LIKE '%wireless buds%' OR LOWER(title) LIKE '%neckband%'
    THEN 'Headphones'
  WHEN LOWER(title) LIKE '%charger%' OR LOWER(title) LIKE '%charging%' OR LOWER(title) LIKE '%cable%' OR LOWER(title) LIKE '%adapter%' OR LOWER(title) LIKE '%dock%' OR LOWER(title) LIKE '%usb c%' OR LOWER(title) LIKE '%type c%' OR LOWER(title) LIKE '%lightning%' OR LOWER(title) LIKE '%power adapter%' OR LOWER(title) LIKE '%usb cable%'
    THEN 'Chargers & Cables'
  WHEN LOWER(title) LIKE '%camera%' OR LOWER(title) LIKE '%dslr%' OR LOWER(title) LIKE '%mirrorless%' OR LOWER(title) LIKE '%canon%' OR LOWER(title) LIKE '%nikon%' OR LOWER(title) LIKE '%gopro%' OR LOWER(title) LIKE '%instax%' OR LOWER(title) LIKE '%webcam%' OR LOWER(title) LIKE '%camcorder%' OR LOWER(title) LIKE '%security camera%'
    THEN 'Cameras'
  WHEN LOWER(title) LIKE '%ssd%' OR LOWER(title) LIKE '%hard drive%' OR LOWER(title) LIKE '%memory card%' OR LOWER(title) LIKE '%flash drive%' OR LOWER(title) LIKE '%pendrive%' OR LOWER(title) LIKE '%hdd%' OR LOWER(title) LIKE '%storage%' OR LOWER(title) LIKE '%micro sd%' OR LOWER(title) LIKE '%sd card%'
    THEN 'Storage'
  WHEN LOWER(title) LIKE '%alexa%' OR LOWER(title) LIKE '%echo%' OR LOWER(title) LIKE '%smart plug%' OR LOWER(title) LIKE '%smart bulb%' OR LOWER(title) LIKE '%smart home%' OR LOWER(title) LIKE '%nest%' OR LOWER(title) LIKE '%homekit%' OR LOWER(title) LIKE '%smart switch%'
    THEN 'Smart Home'
  WHEN LOWER(title) LIKE '%monitor%' OR LOWER(title) LIKE '%display%' OR LOWER(title) LIKE '%tv%' OR LOWER(title) LIKE '%screen%' OR LOWER(title) LIKE '%projector%' OR LOWER(title) LIKE '%oled%' OR LOWER(title) LIKE '%led%' OR LOWER(title) LIKE '%curved monitor%' OR LOWER(title) LIKE '%uhd%' OR LOWER(title) LIKE '%4k%'
    THEN 'TV & Display'
  WHEN LOWER(title) LIKE '%battery%' OR LOWER(title) LIKE '%power bank%' OR LOWER(title) LIKE '%rechargeable%' OR LOWER(title) LIKE '%aa%' OR LOWER(title) LIKE '%aaa%' OR LOWER(title) LIKE '%portable power%' OR LOWER(title) LIKE '%cell%'
    THEN 'Power & Batteries'
  WHEN LOWER(title) LIKE '%wifi%' OR LOWER(title) LIKE '%router%' OR LOWER(title) LIKE '%modem%' OR LOWER(title) LIKE '%ethernet%' OR LOWER(title) LIKE '%access point%' OR LOWER(title) LIKE '%mesh%' OR LOWER(title) LIKE '%network switch%'
    THEN 'Networking'
  WHEN LOWER(title) LIKE '%smartwatch%' OR LOWER(title) LIKE '%fitness band%' OR LOWER(title) LIKE '%fitbit%' OR LOWER(title) LIKE '%watch%' OR LOWER(title) LIKE '%garmin%' OR LOWER(title) LIKE '%amazfit%'
    THEN 'Wearables'
  WHEN LOWER(title) LIKE '%speaker%' OR LOWER(title) LIKE '%soundbar%' OR LOWER(title) LIKE '%subwoofer%' OR LOWER(title) LIKE '%bluetooth speaker%' OR LOWER(title) LIKE '%party speaker%' OR LOWER(title) LIKE '%home theater%'
    THEN 'Speakers'
  WHEN LOWER(title) LIKE '%printer%' OR LOWER(title) LIKE '%scanner%' OR LOWER(title) LIKE '%inkjet%' OR LOWER(title) LIKE '%laserjet%' OR LOWER(title) LIKE '%photocopier%' OR LOWER(title) LIKE '%all in one printer%'
    THEN 'Printers & Scanners'
  WHEN LOWER(title) LIKE '%gaming console%' OR LOWER(title) LIKE '%playstation%' OR LOWER(title) LIKE '%ps5%' OR LOWER(title) LIKE '%ps4%' OR LOWER(title) LIKE '%xbox%' OR LOWER(title) LIKE '%nintendo%' OR LOWER(title) LIKE '%joystick%' OR LOWER(title) LIKE '%controller%' OR LOWER(title) LIKE '%gaming mouse%' OR LOWER(title) LIKE '%gaming keyboard%' OR LOWER(title) LIKE '%gaming chair%'
    THEN 'Gaming'
  ELSE 'Other Electronics'
END;

SELECT category, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY category
ORDER BY cnt DESC;

-- Spot-check the riskiest short keywords for false positives
SELECT title FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Laptops' AND LOWER(title) LIKE '%hp%' AND LOWER(title) NOT LIKE '%hp %' AND LOWER(title) NOT LIKE '% hp%'
LIMIT 10;

SELECT title FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'TV & Display' AND LOWER(title) LIKE '%led%' AND LOWER(title) NOT LIKE '%led %' AND LOWER(title) NOT LIKE '% led%'
LIMIT 10;

SELECT title FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Power & Batteries' AND LOWER(title) NOT LIKE '%battery%' AND LOWER(title) NOT LIKE '%batteries%'
LIMIT 10;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET category = CASE
  WHEN LOWER(title) LIKE '%laptop%' OR LOWER(title) LIKE '%notebook%' OR LOWER(title) LIKE '%macbook%' OR LOWER(title) LIKE '%chromebook%' OR LOWER(title) LIKE '%ultrabook%' OR LOWER(title) LIKE '%acer%' OR LOWER(title) LIKE '%asus%' OR LOWER(title) LIKE '%dell%' OR LOWER(title) LIKE '%lenovo%' OR LOWER(title) REGEXP '\\bhp\\b' OR LOWER(title) LIKE '%core%' OR LOWER(title) LIKE '%intel%' OR LOWER(title) LIKE '%ryzen%' OR LOWER(title) LIKE '%surface%' OR LOWER(title) LIKE '%thinkpad%' OR LOWER(title) LIKE '%ideapad%'
    THEN 'Laptops'
  WHEN LOWER(title) LIKE '%phone%' OR LOWER(title) LIKE '%iphone%' OR LOWER(title) LIKE '%smartphone%' OR LOWER(title) LIKE '%samsung%' OR LOWER(title) LIKE '%android%' OR LOWER(title) LIKE '%galaxy%' OR LOWER(title) LIKE '%pixel%' OR LOWER(title) LIKE '%oneplus%' OR LOWER(title) LIKE '%xiaomi%' OR LOWER(title) LIKE '%oppo%' OR LOWER(title) LIKE '%realme%' OR LOWER(title) LIKE '%huawei%' OR LOWER(title) LIKE '%vivo%' OR LOWER(title) LIKE '%nokia%' OR LOWER(title) LIKE '%motorola%'
    THEN 'Phones'
  WHEN LOWER(title) LIKE '%headphone%' OR LOWER(title) LIKE '%headset%' OR LOWER(title) LIKE '%earphone%' OR LOWER(title) LIKE '%earbuds%' OR LOWER(title) LIKE '%airpods%' OR LOWER(title) LIKE '%beats%' OR LOWER(title) LIKE '%sony wh%' OR LOWER(title) LIKE '%wireless buds%' OR LOWER(title) LIKE '%neckband%'
    THEN 'Headphones'
  WHEN LOWER(title) LIKE '%charger%' OR LOWER(title) LIKE '%charging%' OR LOWER(title) LIKE '%cable%' OR LOWER(title) LIKE '%adapter%' OR LOWER(title) LIKE '%dock%' OR LOWER(title) LIKE '%usb c%' OR LOWER(title) LIKE '%type c%' OR LOWER(title) LIKE '%lightning%' OR LOWER(title) LIKE '%power adapter%' OR LOWER(title) LIKE '%usb cable%'
    THEN 'Chargers & Cables'
  WHEN LOWER(title) LIKE '%camera%' OR LOWER(title) LIKE '%dslr%' OR LOWER(title) LIKE '%mirrorless%' OR LOWER(title) LIKE '%canon%' OR LOWER(title) LIKE '%nikon%' OR LOWER(title) LIKE '%gopro%' OR LOWER(title) LIKE '%instax%' OR LOWER(title) LIKE '%webcam%' OR LOWER(title) LIKE '%camcorder%' OR LOWER(title) LIKE '%security camera%'
    THEN 'Cameras'
  WHEN LOWER(title) LIKE '%ssd%' OR LOWER(title) LIKE '%hard drive%' OR LOWER(title) LIKE '%memory card%' OR LOWER(title) LIKE '%flash drive%' OR LOWER(title) LIKE '%pendrive%' OR LOWER(title) LIKE '%hdd%' OR LOWER(title) LIKE '%storage%' OR LOWER(title) LIKE '%micro sd%' OR LOWER(title) LIKE '%sd card%'
    THEN 'Storage'
  WHEN LOWER(title) LIKE '%alexa%' OR LOWER(title) LIKE '%echo%' OR LOWER(title) LIKE '%smart plug%' OR LOWER(title) LIKE '%smart bulb%' OR LOWER(title) LIKE '%smart home%' OR LOWER(title) LIKE '%nest%' OR LOWER(title) LIKE '%homekit%' OR LOWER(title) LIKE '%smart switch%'
    THEN 'Smart Home'
  WHEN LOWER(title) LIKE '%monitor%' OR LOWER(title) LIKE '%display%' OR LOWER(title) LIKE '%tv%' OR LOWER(title) LIKE '%screen%' OR LOWER(title) LIKE '%projector%' OR LOWER(title) LIKE '%oled%' OR LOWER(title) REGEXP '\\bled\\b' OR LOWER(title) LIKE '%curved monitor%' OR LOWER(title) LIKE '%uhd%' OR LOWER(title) LIKE '%4k%'
    THEN 'TV & Display'
  WHEN LOWER(title) LIKE '%battery%' OR LOWER(title) LIKE '%power bank%' OR LOWER(title) REGEXP '\\baa\\b' OR LOWER(title) REGEXP '\\baaa\\b' OR LOWER(title) LIKE '%portable power%' OR LOWER(title) REGEXP '\\bcell\\b'
    THEN 'Power & Batteries'
  WHEN LOWER(title) LIKE '%wifi%' OR LOWER(title) LIKE '%router%' OR LOWER(title) LIKE '%modem%' OR LOWER(title) LIKE '%ethernet%' OR LOWER(title) LIKE '%access point%' OR LOWER(title) LIKE '%mesh%' OR LOWER(title) LIKE '%network switch%'
    THEN 'Networking'
  WHEN LOWER(title) LIKE '%smartwatch%' OR LOWER(title) LIKE '%fitness band%' OR LOWER(title) LIKE '%fitbit%' OR LOWER(title) LIKE '%watch%' OR LOWER(title) LIKE '%garmin%' OR LOWER(title) LIKE '%amazfit%'
    THEN 'Wearables'
  WHEN LOWER(title) LIKE '%speaker%' OR LOWER(title) LIKE '%soundbar%' OR LOWER(title) LIKE '%subwoofer%' OR LOWER(title) LIKE '%bluetooth speaker%' OR LOWER(title) LIKE '%party speaker%' OR LOWER(title) LIKE '%home theater%'
    THEN 'Speakers'
  WHEN LOWER(title) LIKE '%printer%' OR LOWER(title) LIKE '%scanner%' OR LOWER(title) LIKE '%inkjet%' OR LOWER(title) LIKE '%laserjet%' OR LOWER(title) LIKE '%photocopier%' OR LOWER(title) LIKE '%all in one printer%'
    THEN 'Printers & Scanners'
  WHEN LOWER(title) LIKE '%gaming console%' OR LOWER(title) LIKE '%playstation%' OR LOWER(title) LIKE '%ps5%' OR LOWER(title) LIKE '%ps4%' OR LOWER(title) LIKE '%xbox%' OR LOWER(title) LIKE '%nintendo%' OR LOWER(title) LIKE '%joystick%' OR LOWER(title) LIKE '%controller%' OR LOWER(title) LIKE '%gaming mouse%' OR LOWER(title) LIKE '%gaming keyboard%' OR LOWER(title) LIKE '%gaming chair%'
    THEN 'Gaming'
  ELSE 'Other Electronics'
END;

SELECT category, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY category
ORDER BY cnt DESC;

SELECT title FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Laptops' AND (LOWER(title) LIKE '%splashproof%' OR LOWER(title) LIKE '%12vhpwr%');

SELECT title FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'TV & Display' AND (LOWER(title) LIKE '%controlled%' OR LOWER(title) LIKE '%recycled%' OR LOWER(title) LIKE '%assembled%')
  AND LOWER(title) NOT LIKE '%tv%' AND LOWER(title) NOT LIKE '%monitor%' AND LOWER(title) NOT LIKE '%display%';

SELECT title FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Power & Batteries' AND LOWER(title) LIKE '%cellular%';

SELECT COUNT(*) AS screen_protector_miscategorized
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'TV & Display' AND LOWER(title) LIKE '%screen protector%';

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET category = CASE
  WHEN LOWER(title) LIKE '%laptop%' OR LOWER(title) LIKE '%notebook%' OR LOWER(title) LIKE '%macbook%' OR LOWER(title) LIKE '%chromebook%' OR LOWER(title) LIKE '%ultrabook%' OR LOWER(title) LIKE '%acer%' OR LOWER(title) LIKE '%asus%' OR LOWER(title) LIKE '%dell%' OR LOWER(title) LIKE '%lenovo%' OR LOWER(title) REGEXP '\\bhp\\b' OR LOWER(title) LIKE '%core%' OR LOWER(title) LIKE '%intel%' OR LOWER(title) LIKE '%ryzen%' OR LOWER(title) LIKE '%surface%' OR LOWER(title) LIKE '%thinkpad%' OR LOWER(title) LIKE '%ideapad%'
    THEN 'Laptops'
  WHEN LOWER(title) LIKE '%phone%' OR LOWER(title) LIKE '%iphone%' OR LOWER(title) LIKE '%smartphone%' OR LOWER(title) LIKE '%samsung%' OR LOWER(title) LIKE '%android%' OR LOWER(title) LIKE '%galaxy%' OR LOWER(title) LIKE '%pixel%' OR LOWER(title) LIKE '%oneplus%' OR LOWER(title) LIKE '%xiaomi%' OR LOWER(title) LIKE '%oppo%' OR LOWER(title) LIKE '%realme%' OR LOWER(title) LIKE '%huawei%' OR LOWER(title) LIKE '%vivo%' OR LOWER(title) LIKE '%nokia%' OR LOWER(title) LIKE '%motorola%'
    THEN 'Phones'
  WHEN LOWER(title) LIKE '%headphone%' OR LOWER(title) LIKE '%headset%' OR LOWER(title) LIKE '%earphone%' OR LOWER(title) LIKE '%earbuds%' OR LOWER(title) LIKE '%airpods%' OR LOWER(title) LIKE '%beats%' OR LOWER(title) LIKE '%sony wh%' OR LOWER(title) LIKE '%wireless buds%' OR LOWER(title) LIKE '%neckband%'
    THEN 'Headphones'
  WHEN LOWER(title) LIKE '%charger%' OR LOWER(title) LIKE '%charging%' OR LOWER(title) LIKE '%cable%' OR LOWER(title) LIKE '%adapter%' OR LOWER(title) LIKE '%dock%' OR LOWER(title) LIKE '%usb c%' OR LOWER(title) LIKE '%type c%' OR LOWER(title) LIKE '%lightning%' OR LOWER(title) LIKE '%power adapter%' OR LOWER(title) LIKE '%usb cable%'
    THEN 'Chargers & Cables'
  WHEN LOWER(title) LIKE '%camera%' OR LOWER(title) LIKE '%dslr%' OR LOWER(title) LIKE '%mirrorless%' OR LOWER(title) LIKE '%canon%' OR LOWER(title) LIKE '%nikon%' OR LOWER(title) LIKE '%gopro%' OR LOWER(title) LIKE '%instax%' OR LOWER(title) LIKE '%webcam%' OR LOWER(title) LIKE '%camcorder%' OR LOWER(title) LIKE '%security camera%'
    THEN 'Cameras'
  WHEN LOWER(title) LIKE '%ssd%' OR LOWER(title) LIKE '%hard drive%' OR LOWER(title) LIKE '%memory card%' OR LOWER(title) LIKE '%flash drive%' OR LOWER(title) LIKE '%pendrive%' OR LOWER(title) LIKE '%hdd%' OR LOWER(title) LIKE '%storage%' OR LOWER(title) LIKE '%micro sd%' OR LOWER(title) LIKE '%sd card%'
    THEN 'Storage'
  WHEN LOWER(title) LIKE '%alexa%' OR LOWER(title) LIKE '%echo%' OR LOWER(title) LIKE '%smart plug%' OR LOWER(title) LIKE '%smart bulb%' OR LOWER(title) LIKE '%smart home%' OR LOWER(title) LIKE '%nest%' OR LOWER(title) LIKE '%homekit%' OR LOWER(title) LIKE '%smart switch%'
    THEN 'Smart Home'
  WHEN LOWER(title) LIKE '%monitor%' OR LOWER(title) LIKE '%display%' OR LOWER(title) LIKE '%tv%' OR LOWER(title) LIKE '%projector%' OR LOWER(title) LIKE '%oled%' OR LOWER(title) REGEXP '\\bled\\b' OR LOWER(title) LIKE '%curved monitor%' OR LOWER(title) LIKE '%uhd%' OR LOWER(title) LIKE '%4k%'
    THEN 'TV & Display'
  WHEN LOWER(title) LIKE '%battery%' OR LOWER(title) LIKE '%power bank%' OR LOWER(title) REGEXP '\\baa\\b' OR LOWER(title) REGEXP '\\baaa\\b' OR LOWER(title) LIKE '%portable power%' OR LOWER(title) REGEXP '\\bcell\\b'
    THEN 'Power & Batteries'
  WHEN LOWER(title) LIKE '%wifi%' OR LOWER(title) LIKE '%router%' OR LOWER(title) LIKE '%modem%' OR LOWER(title) LIKE '%ethernet%' OR LOWER(title) LIKE '%access point%' OR LOWER(title) LIKE '%mesh%' OR LOWER(title) LIKE '%network switch%'
    THEN 'Networking'
  WHEN LOWER(title) LIKE '%smartwatch%' OR LOWER(title) LIKE '%fitness band%' OR LOWER(title) LIKE '%fitbit%' OR LOWER(title) LIKE '%watch%' OR LOWER(title) LIKE '%garmin%' OR LOWER(title) LIKE '%amazfit%'
    THEN 'Wearables'
  WHEN LOWER(title) LIKE '%speaker%' OR LOWER(title) LIKE '%soundbar%' OR LOWER(title) LIKE '%subwoofer%' OR LOWER(title) LIKE '%bluetooth speaker%' OR LOWER(title) LIKE '%party speaker%' OR LOWER(title) LIKE '%home theater%'
    THEN 'Speakers'
  WHEN LOWER(title) LIKE '%printer%' OR LOWER(title) LIKE '%scanner%' OR LOWER(title) LIKE '%inkjet%' OR LOWER(title) LIKE '%laserjet%' OR LOWER(title) LIKE '%photocopier%' OR LOWER(title) LIKE '%all in one printer%'
    THEN 'Printers & Scanners'
  WHEN LOWER(title) LIKE '%gaming console%' OR LOWER(title) LIKE '%playstation%' OR LOWER(title) LIKE '%ps5%' OR LOWER(title) LIKE '%ps4%' OR LOWER(title) LIKE '%xbox%' OR LOWER(title) LIKE '%nintendo%' OR LOWER(title) LIKE '%joystick%' OR LOWER(title) LIKE '%controller%' OR LOWER(title) LIKE '%gaming mouse%' OR LOWER(title) LIKE '%gaming keyboard%' OR LOWER(title) LIKE '%gaming chair%'
    THEN 'Gaming'
  ELSE 'Other Electronics'
END;

SELECT category, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY category
ORDER BY cnt DESC;

SELECT COUNT(*) AS remaining_screen_protector_issue
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'TV & Display' AND LOWER(title) LIKE '%screen protector%';

	SELECT title, category
	FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
	WHERE category = 'TV & Display' AND LOWER(title) LIKE '%screen protector%';
    
-- How many "Laptops" rows are actually printer supplies?
SELECT COUNT(*) AS brand_printer_overlap
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Laptops'
  AND (LOWER(title) LIKE '%toner%' OR LOWER(title) LIKE '%cartridge%' OR LOWER(title) LIKE '%printer%' OR LOWER(title) LIKE '%inkjet%' OR LOWER(title) LIKE '%laserjet%')
  AND LOWER(title) NOT LIKE '%laptop%' AND LOWER(title) NOT LIKE '%notebook%' AND LOWER(title) NOT LIKE '%macbook%' AND LOWER(title) NOT LIKE '%chromebook%' AND LOWER(title) NOT LIKE '%ultrabook%' AND LOWER(title) NOT LIKE '%thinkpad%' AND LOWER(title) NOT LIKE '%ideapad%';
  
-- Does the exact same Celestron false positive exist in our table?
SELECT title, category FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE LOWER(title) LIKE '%celestron%' OR LOWER(title) LIKE '%telescope%' OR LOWER(title) LIKE '%observatory%';

-- Broader check: how many "Laptops" matches rely ONLY on an ambiguous brand/spec word,
-- with no actual laptop-type word anywhere in the title?
SELECT COUNT(*) AS ambiguous_only_matches
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Laptops'
  AND LOWER(title) NOT LIKE '%laptop%' AND LOWER(title) NOT LIKE '%notebook%' AND LOWER(title) NOT LIKE '%macbook%' AND LOWER(title) NOT LIKE '%chromebook%' AND LOWER(title) NOT LIKE '%ultrabook%' AND LOWER(title) NOT LIKE '%thinkpad%' AND LOWER(title) NOT LIKE '%ideapad%';
  
UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET category = CASE
  WHEN LOWER(title) LIKE '%printer%' OR LOWER(title) LIKE '%scanner%' OR LOWER(title) LIKE '%inkjet%' OR LOWER(title) LIKE '%laserjet%' OR LOWER(title) LIKE '%photocopier%' OR LOWER(title) LIKE '%all in one printer%'
    THEN 'Printers & Scanners'
  WHEN LOWER(title) LIKE '%telescope%' OR LOWER(title) LIKE '%binocular%' OR LOWER(title) LIKE '%monocular%' OR LOWER(title) LIKE '%dobsonian%' OR LOWER(title) LIKE '%refractor%' OR LOWER(title) LIKE '%reflector%' OR LOWER(title) LIKE '%eyepiece%' OR LOWER(title) LIKE '%spotting scope%'
    THEN 'Optics & Outdoor'
  WHEN LOWER(title) LIKE '%headphone%' OR LOWER(title) LIKE '%headset%' OR LOWER(title) LIKE '%earphone%' OR LOWER(title) LIKE '%earbuds%' OR LOWER(title) LIKE '%airpods%' OR LOWER(title) LIKE '%beats%' OR LOWER(title) LIKE '%sony wh%' OR LOWER(title) LIKE '%wireless buds%' OR LOWER(title) LIKE '%neckband%'
    THEN 'Headphones'
  WHEN LOWER(title) LIKE '%charger%' OR LOWER(title) LIKE '%charging%' OR LOWER(title) LIKE '%cable%' OR LOWER(title) LIKE '%adapter%' OR LOWER(title) LIKE '%dock%' OR LOWER(title) LIKE '%usb c%' OR LOWER(title) LIKE '%type c%' OR LOWER(title) LIKE '%lightning%' OR LOWER(title) LIKE '%power adapter%' OR LOWER(title) LIKE '%usb cable%'
    THEN 'Chargers & Cables'
  WHEN LOWER(title) LIKE '%camera%' OR LOWER(title) LIKE '%dslr%' OR LOWER(title) LIKE '%mirrorless%' OR LOWER(title) LIKE '%canon%' OR LOWER(title) LIKE '%nikon%' OR LOWER(title) LIKE '%gopro%' OR LOWER(title) LIKE '%instax%' OR LOWER(title) LIKE '%webcam%' OR LOWER(title) LIKE '%camcorder%' OR LOWER(title) LIKE '%security camera%'
    THEN 'Cameras'
  WHEN LOWER(title) LIKE '%ssd%' OR LOWER(title) LIKE '%hard drive%' OR LOWER(title) LIKE '%memory card%' OR LOWER(title) LIKE '%flash drive%' OR LOWER(title) LIKE '%pendrive%' OR LOWER(title) LIKE '%hdd%' OR LOWER(title) LIKE '%storage%' OR LOWER(title) LIKE '%micro sd%' OR LOWER(title) LIKE '%sd card%'
    THEN 'Storage'
  WHEN LOWER(title) LIKE '%alexa%' OR LOWER(title) LIKE '%echo%' OR LOWER(title) LIKE '%smart plug%' OR LOWER(title) LIKE '%smart bulb%' OR LOWER(title) LIKE '%smart home%' OR LOWER(title) REGEXP '\\bnest\\b' OR LOWER(title) LIKE '%homekit%' OR LOWER(title) LIKE '%smart switch%'
    THEN 'Smart Home'
  WHEN LOWER(title) LIKE '%monitor%' OR LOWER(title) LIKE '%display%' OR LOWER(title) REGEXP '\\btv\\b' OR LOWER(title) LIKE '%projector%' OR LOWER(title) LIKE '%oled%' OR LOWER(title) REGEXP '\\bled\\b' OR LOWER(title) LIKE '%curved monitor%' OR LOWER(title) LIKE '%uhd%' OR LOWER(title) LIKE '%4k%'
    THEN 'TV & Display'
  WHEN LOWER(title) LIKE '%battery%' OR LOWER(title) LIKE '%power bank%' OR LOWER(title) REGEXP '\\baa\\b' OR LOWER(title) REGEXP '\\baaa\\b' OR LOWER(title) LIKE '%portable power%' OR LOWER(title) REGEXP '\\bcell\\b'
    THEN 'Power & Batteries'
  WHEN LOWER(title) LIKE '%wifi%' OR LOWER(title) LIKE '%router%' OR LOWER(title) LIKE '%modem%' OR LOWER(title) LIKE '%ethernet%' OR LOWER(title) LIKE '%access point%' OR LOWER(title) LIKE '%mesh%' OR LOWER(title) LIKE '%network switch%'
    THEN 'Networking'
  WHEN LOWER(title) LIKE '%smartwatch%' OR LOWER(title) LIKE '%fitness band%' OR LOWER(title) LIKE '%fitbit%' OR LOWER(title) LIKE '%watch%' OR LOWER(title) LIKE '%garmin%' OR LOWER(title) LIKE '%amazfit%'
    THEN 'Wearables'
  WHEN LOWER(title) LIKE '%speaker%' OR LOWER(title) LIKE '%soundbar%' OR LOWER(title) LIKE '%subwoofer%' OR LOWER(title) LIKE '%bluetooth speaker%' OR LOWER(title) LIKE '%party speaker%' OR LOWER(title) LIKE '%home theater%'
    THEN 'Speakers'
  WHEN LOWER(title) LIKE '%gaming console%' OR LOWER(title) LIKE '%playstation%' OR LOWER(title) LIKE '%ps5%' OR LOWER(title) LIKE '%ps4%' OR LOWER(title) LIKE '%xbox%' OR LOWER(title) LIKE '%nintendo%' OR LOWER(title) LIKE '%joystick%' OR LOWER(title) LIKE '%controller%' OR LOWER(title) LIKE '%gaming mouse%' OR LOWER(title) LIKE '%gaming keyboard%' OR LOWER(title) LIKE '%gaming chair%'
    THEN 'Gaming'
  WHEN LOWER(title) LIKE '%phone%' OR LOWER(title) LIKE '%iphone%' OR LOWER(title) LIKE '%smartphone%' OR LOWER(title) LIKE '%samsung%' OR LOWER(title) LIKE '%android%' OR LOWER(title) LIKE '%galaxy%' OR LOWER(title) LIKE '%pixel%' OR LOWER(title) LIKE '%oneplus%' OR LOWER(title) LIKE '%xiaomi%' OR LOWER(title) LIKE '%oppo%' OR LOWER(title) LIKE '%realme%' OR LOWER(title) LIKE '%huawei%' OR LOWER(title) LIKE '%vivo%' OR LOWER(title) LIKE '%nokia%' OR LOWER(title) LIKE '%motorola%'
    THEN 'Phones'
  WHEN LOWER(title) LIKE '%laptop%' OR LOWER(title) LIKE '%notebook%' OR LOWER(title) LIKE '%macbook%' OR LOWER(title) LIKE '%chromebook%' OR LOWER(title) LIKE '%ultrabook%' OR LOWER(title) LIKE '%acer%' OR LOWER(title) LIKE '%asus%' OR LOWER(title) LIKE '%dell%' OR LOWER(title) LIKE '%lenovo%' OR LOWER(title) REGEXP '\\bhp\\b' OR LOWER(title) REGEXP '\\bcore\\b' OR LOWER(title) REGEXP '\\bintel\\b' OR LOWER(title) LIKE '%ryzen%' OR LOWER(title) REGEXP '\\bsurface\\b' OR LOWER(title) LIKE '%thinkpad%' OR LOWER(title) LIKE '%ideapad%'
    THEN 'Laptops'
  ELSE 'Other Electronics'
END;

SELECT category, COUNT(*) AS cnt
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
GROUP BY category
ORDER BY cnt DESC;

-- Should now be 0: telescopes/binoculars stolen by Phones/Networking/Laptops
SELECT COUNT(*) AS misplaced_telescopes
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category IN ('Phones','Networking','Laptops')
  AND (LOWER(title) LIKE '%telescope%' OR LOWER(title) LIKE '%binocular%');
  
-- Re-check printer overlap (should now be near 0, since Printers & Scanners is checked first)
SELECT COUNT(*) AS brand_printer_overlap
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Laptops'
  AND (LOWER(title) LIKE '%toner%' OR LOWER(title) LIKE '%cartridge%' OR LOWER(title) LIKE '%printer%');
  
SELECT COUNT(*) AS ambiguous_only_matches
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Laptops'
  AND LOWER(title) NOT LIKE '%laptop%' AND LOWER(title) NOT LIKE '%notebook%' AND LOWER(title) NOT LIKE '%macbook%' AND LOWER(title) NOT LIKE '%chromebook%' AND LOWER(title) NOT LIKE '%ultrabook%' AND LOWER(title) NOT LIKE '%thinkpad%' AND LOWER(title) NOT LIKE '%ideapad%';
  
SELECT title
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Laptops'
  AND (LOWER(title) LIKE '%toner%' OR LOWER(title) LIKE '%cartridge%' OR LOWER(title) LIKE '%printer%')
LIMIT 41;

UPDATE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
SET category = CASE
  WHEN LOWER(title) LIKE '%printer%' OR LOWER(title) LIKE '%scanner%' OR LOWER(title) LIKE '%inkjet%' OR LOWER(title) LIKE '%laserjet%' OR LOWER(title) LIKE '%photocopier%' OR LOWER(title) LIKE '%all in one printer%' OR LOWER(title) LIKE '%ink cartridge%' OR LOWER(title) LIKE '%toner%' OR LOWER(title) LIKE '%cartridge%'
    THEN 'Printers & Scanners'
  WHEN LOWER(title) LIKE '%telescope%' OR LOWER(title) LIKE '%binocular%' OR LOWER(title) LIKE '%monocular%' OR LOWER(title) LIKE '%dobsonian%' OR LOWER(title) LIKE '%refractor%' OR LOWER(title) LIKE '%reflector%' OR LOWER(title) LIKE '%eyepiece%' OR LOWER(title) LIKE '%spotting scope%'
    THEN 'Optics & Outdoor'
  WHEN LOWER(title) LIKE '%headphone%' OR LOWER(title) LIKE '%headset%' OR LOWER(title) LIKE '%earphone%' OR LOWER(title) LIKE '%earbuds%' OR LOWER(title) LIKE '%airpods%' OR LOWER(title) LIKE '%beats%' OR LOWER(title) LIKE '%sony wh%' OR LOWER(title) LIKE '%wireless buds%' OR LOWER(title) LIKE '%neckband%'
    THEN 'Headphones'
  WHEN LOWER(title) LIKE '%charger%' OR LOWER(title) LIKE '%charging%' OR LOWER(title) LIKE '%cable%' OR LOWER(title) LIKE '%adapter%' OR LOWER(title) LIKE '%dock%' OR LOWER(title) LIKE '%usb c%' OR LOWER(title) LIKE '%type c%' OR LOWER(title) LIKE '%lightning%' OR LOWER(title) LIKE '%power adapter%' OR LOWER(title) LIKE '%usb cable%'
    THEN 'Chargers & Cables'
  WHEN LOWER(title) LIKE '%camera%' OR LOWER(title) LIKE '%dslr%' OR LOWER(title) LIKE '%mirrorless%' OR LOWER(title) LIKE '%canon%' OR LOWER(title) LIKE '%nikon%' OR LOWER(title) LIKE '%gopro%' OR LOWER(title) LIKE '%instax%' OR LOWER(title) LIKE '%webcam%' OR LOWER(title) LIKE '%camcorder%' OR LOWER(title) LIKE '%security camera%'
    THEN 'Cameras'
  WHEN LOWER(title) LIKE '%ssd%' OR LOWER(title) LIKE '%hard drive%' OR LOWER(title) LIKE '%memory card%' OR LOWER(title) LIKE '%flash drive%' OR LOWER(title) LIKE '%pendrive%' OR LOWER(title) LIKE '%hdd%' OR LOWER(title) LIKE '%storage%' OR LOWER(title) LIKE '%micro sd%' OR LOWER(title) LIKE '%sd card%'
    THEN 'Storage'
  WHEN LOWER(title) LIKE '%alexa%' OR LOWER(title) LIKE '%echo%' OR LOWER(title) LIKE '%smart plug%' OR LOWER(title) LIKE '%smart bulb%' OR LOWER(title) LIKE '%smart home%' OR LOWER(title) REGEXP '\\bnest\\b' OR LOWER(title) LIKE '%homekit%' OR LOWER(title) LIKE '%smart switch%'
    THEN 'Smart Home'
  WHEN LOWER(title) LIKE '%monitor%' OR LOWER(title) LIKE '%display%' OR LOWER(title) REGEXP '\\btv\\b' OR LOWER(title) LIKE '%projector%' OR LOWER(title) LIKE '%oled%' OR LOWER(title) REGEXP '\\bled\\b' OR LOWER(title) LIKE '%curved monitor%' OR LOWER(title) LIKE '%uhd%' OR LOWER(title) LIKE '%4k%'
    THEN 'TV & Display'
  WHEN LOWER(title) LIKE '%battery%' OR LOWER(title) LIKE '%power bank%' OR LOWER(title) REGEXP '\\baa\\b' OR LOWER(title) REGEXP '\\baaa\\b' OR LOWER(title) LIKE '%portable power%' OR LOWER(title) REGEXP '\\bcell\\b'
    THEN 'Power & Batteries'
  WHEN LOWER(title) LIKE '%wifi%' OR LOWER(title) LIKE '%router%' OR LOWER(title) LIKE '%modem%' OR LOWER(title) LIKE '%ethernet%' OR LOWER(title) LIKE '%access point%' OR LOWER(title) LIKE '%mesh%' OR LOWER(title) LIKE '%network switch%'
    THEN 'Networking'
  WHEN LOWER(title) LIKE '%smartwatch%' OR LOWER(title) LIKE '%fitness band%' OR LOWER(title) LIKE '%fitbit%' OR LOWER(title) LIKE '%watch%' OR LOWER(title) LIKE '%garmin%' OR LOWER(title) LIKE '%amazfit%'
    THEN 'Wearables'
  WHEN LOWER(title) LIKE '%speaker%' OR LOWER(title) LIKE '%soundbar%' OR LOWER(title) LIKE '%subwoofer%' OR LOWER(title) LIKE '%bluetooth speaker%' OR LOWER(title) LIKE '%party speaker%' OR LOWER(title) LIKE '%home theater%'
    THEN 'Speakers'
  WHEN LOWER(title) LIKE '%gaming console%' OR LOWER(title) LIKE '%playstation%' OR LOWER(title) LIKE '%ps5%' OR LOWER(title) LIKE '%ps4%' OR LOWER(title) LIKE '%xbox%' OR LOWER(title) LIKE '%nintendo%' OR LOWER(title) LIKE '%joystick%' OR LOWER(title) LIKE '%controller%' OR LOWER(title) LIKE '%gaming mouse%' OR LOWER(title) LIKE '%gaming keyboard%' OR LOWER(title) LIKE '%gaming chair%'
    THEN 'Gaming'
  WHEN LOWER(title) LIKE '%phone%' OR LOWER(title) LIKE '%iphone%' OR LOWER(title) LIKE '%smartphone%' OR LOWER(title) LIKE '%samsung%' OR LOWER(title) LIKE '%android%' OR LOWER(title) LIKE '%galaxy%' OR LOWER(title) LIKE '%pixel%' OR LOWER(title) LIKE '%oneplus%' OR LOWER(title) LIKE '%xiaomi%' OR LOWER(title) LIKE '%oppo%' OR LOWER(title) LIKE '%realme%' OR LOWER(title) LIKE '%huawei%' OR LOWER(title) LIKE '%vivo%' OR LOWER(title) LIKE '%nokia%' OR LOWER(title) LIKE '%motorola%'
    THEN 'Phones'
  WHEN LOWER(title) LIKE '%laptop%' OR LOWER(title) LIKE '%notebook%' OR LOWER(title) LIKE '%macbook%' OR LOWER(title) LIKE '%chromebook%' OR LOWER(title) LIKE '%ultrabook%' OR LOWER(title) LIKE '%acer%' OR LOWER(title) LIKE '%asus%' OR LOWER(title) LIKE '%dell%' OR LOWER(title) LIKE '%lenovo%' OR LOWER(title) REGEXP '\\bhp\\b' OR LOWER(title) REGEXP '\\bcore\\b' OR LOWER(title) REGEXP '\\bintel\\b' OR LOWER(title) LIKE '%ryzen%' OR LOWER(title) REGEXP '\\bsurface\\b' OR LOWER(title) LIKE '%thinkpad%' OR LOWER(title) LIKE '%ideapad%'
    THEN 'Laptops'
  ELSE 'Other Electronics'
END;

SELECT COUNT(*) AS brand_printer_overlap
FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Laptops'
  AND (LOWER(title) LIKE '%toner%' OR LOWER(title) LIKE '%cartridge%' OR LOWER(title) LIKE '%printer%');
  
SELECT title FROM `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
WHERE category = 'Laptops'
  AND LOWER(title) NOT LIKE '%laptop%' AND LOWER(title) NOT LIKE '%notebook%' AND LOWER(title) NOT LIKE '%macbook%' AND LOWER(title) NOT LIKE '%chromebook%' AND LOWER(title) NOT LIKE '%ultrabook%' AND LOWER(title) NOT LIKE '%thinkpad%' AND LOWER(title) NOT LIKE '%ideapad%'
ORDER BY RAND()
LIMIT 25;

RENAME TABLE `Amazon sales 2025`.`amazon_products_sales_data_cleaned`
TO `Amazon sales 2025`.`amazon_data_cleaned`;


SELECT COUNT(*) AS titles_with_quote_char
FROM `Amazon sales 2025`.`amazon_data_cleaned`
WHERE title LIKE '%"%';

UPDATE `Amazon sales 2025`.`amazon_data_cleaned`
SET title = REPLACE(title, '"', 'in');

SELECT COUNT(*) AS remaining_quotes
FROM `Amazon sales 2025`.`amazon_data_cleaned`
WHERE title LIKE '%"%';

SELECT
  title,
  rating_clean AS rating,
  reviews_clean AS total_reviews,
  bought_last_month_clean AS purchased_last_month_est,
  current_price_clean AS current_price,
  listed_price_clean AS listed_price,
  discount_percentage,
  is_best_seller_flag AS is_best_seller,
  is_sponsored_flag AS is_sponsored,
  buy_box_available,
  has_coupon,
  coupon_type,
  coupon_amount,
  collected_at_clean AS collected_at,
  delivery_date_clean AS delivery_date,
  product_url_clean AS product_url,
  image_url,
  sustainability_badges,
  category
FROM `Amazon sales 2025`.`amazon_data_cleaned`;