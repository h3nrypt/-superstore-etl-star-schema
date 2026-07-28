-- =========================================================================
-- FILE 03: DATE ENGINE SETUP
-- Purpose: Compile calendar structure and populate continuous time matrix.
-- =========================================================================

USE superstore_db;

DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
    date_key DATE NOT NULL,
    year INT NOT NULL,
    quarter VARCHAR(2) NOT NULL,
    month_num INT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    day_num INT NOT NULL,
    day_name VARCHAR(15) NOT NULL,
    day_of_week INT NOT NULL,
    is_weekend TINYINT NOT NULL, 
    PRIMARY KEY (date_key)
);

DELIMITER //

DROP PROCEDURE IF EXISTS populate_date_dimension//

CREATE PROCEDURE populate_date_dimension(start_date DATE, end_date DATE)
BEGIN
    DECLARE current_date_val DATE;
    SET current_date_val = start_date;
    
    SET AUTOCOMMIT = 0;
    
    WHILE current_date_val <= end_date DO
        INSERT INTO dim_date (
            date_key, year, quarter, month_num, month_name, 
            day_num, day_name, day_of_week, is_weekend
        ) VALUES (
            current_date_val,
            YEAR(current_date_val),
            CONCAT('Q', QUARTER(current_date_val)),
            MONTH(current_date_val),
            MONTHNAME(current_date_val),
            DAYOFMONTH(current_date_val),
            DAYNAME(current_date_val),
            DAYOFWEEK(current_date_val),
            IF(DAYOFWEEK(current_date_val) IN (1, 7), 1, 0)
        );
        
        SET current_date_val = ADDDATE(current_date_val, INTERVAL 1 DAY);
    END WHILE;
    
    COMMIT;
    SET AUTOCOMMIT = 1;
END//

DELIMITER ;

-- Execute data loading
CALL populate_date_dimension('2014-01-01', '2018-01-31');
