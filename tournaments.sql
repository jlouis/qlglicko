INSERT INTO tournament (t_from, t_to)
  SELECT max(t_to), max(t_to) + '7 days' :: interval FROM tournament;
  

