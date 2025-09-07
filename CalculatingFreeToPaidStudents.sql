USE db_course_conversions;

DROP TABLE IF EXISTS student_full;

CREATE TABLE student_full (
    student_id INT UNIQUE,
    date_registered DATE,
    first_date_watched DATE,
    first_date_purchased DATE NULL,
    date_diff_reg_watch INT,
    date_diff_watch_purch INT NULL
);

TRUNCATE TABLE student_full;


INSERT INTO student_full
WITH student_dates AS (
	SELECT 
		i.student_id,
		i.date_registered,
		MIN(e.date_watched)		AS first_date_watched,
		MIN(p.date_purchased)	AS first_date_purchased
	FROM
		student_info i
		JOIN student_engagement e		ON i.student_id = e.student_id
        LEFT JOIN student_purchases p		ON i.student_id = p.student_id
	GROUP BY 
		i.student_id, 
        i.date_registered
)
SELECT
    student_id,
    date_registered,
    first_date_watched,
    first_date_purchased,
	DATEDIFF(first_date_watched, date_registered)		AS date_diff_reg_watch,
	DATEDIFF(first_date_purchased, first_date_watched)	AS date_diff_watch_purch
FROM
	student_dates
WHERE 
	first_date_watched IS NOT NULL
		AND (first_date_purchased IS NULL OR first_date_watched <= first_date_purchased)
ORDER BY student_id;

COMMIT;


-- Calculate intermediate parameters
WITH agg AS ( 
	SELECT
		COUNT(student_id) AS total_watched,
		COUNT(first_date_purchased) AS total_purchased,
		SUM(date_diff_reg_watch) AS sum_reg_watch,
		SUM(date_diff_watch_purch) AS sum_watch_purch
	FROM
		student_full
)

SELECT
	-- 1. Free-to-Paid Conversion Rate
    ROUND(
		agg.total_purchased * 100.0
        / agg.total_watched,
        2
	) AS conversion_rate,
    -- 2. Average duration between registration and first-time engagement
    ROUND(
		agg.sum_reg_watch
        / agg.total_watched,
        2
	) AS av_reg_watch,
    -- 3. Average duration between first-time engagement and first-time purchase
    ROUND(
		agg.sum_watch_purch
        / NULLIF(agg.total_purchased, 0),
        2
	) AS av_watch_purch
FROM agg;

SELECT student_id, first_date_watched FROM student_full WHERE student_id = 268727;
SELECT * FROM student_full WHERE student_id = 268727;