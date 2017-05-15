select LGA_NAME, count(*) from school_locations group by LGA_NAME order by LGA_NAME

select LGA_NAME, school_type, count(*) from school_locations group by LGA_NAME, school_type order by LGA_NAME, school_type

