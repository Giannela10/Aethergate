-- Run after the migration. Compatible with the campus distribution in AGENTS.md.
insert into public.subjects(code,name,floor,area) values
('INF_GENERAL','Informática General',3,'Informática y Telecomunicaciones'),
('BASE_DATOS','Bases de Datos',3,'Informática y Telecomunicaciones'),
('ALGORITMOS','Algoritmos y Programación',3,'Informática y Telecomunicaciones'),
('REDES','Redes y Telecomunicaciones',3,'Informática y Telecomunicaciones'),
('INGLES','Inglés',6,'Formación general'),('ETICA','Ética',6,'Formación general'),
('COMUNICACION','Habilidades de Comunicación',7,'Formación general'),('MATEMATICAS','Matemáticas',7,'Formación general'),
('ENFERMERIA','Enfermería',4,'Sector norte · Salud'),('ODONTOLOGIA','Odontología',4,'Sector norte · Salud')
on conflict(code) do nothing;
