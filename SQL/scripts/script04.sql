   select distinct 
          t.book_ref,
          bp.boarding_no    
     from tickets as t
left join boarding_passes as bp
       on bp.ticket_no = t.ticket_no
    where bp.boarding_no is null;   
