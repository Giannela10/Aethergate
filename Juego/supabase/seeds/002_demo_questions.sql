-- Optional development data. Run in SQL editor AFTER creating an admin identity.
-- Does not ship answer keys in production game assets.
do $$
declare author_id uuid; subject uuid; q uuid;
begin
 select id into author_id from public.profiles where role='admin' limit 1;
 if author_id is null then raise exception 'Assign an admin first'; end if;
 select id into strict subject from public.subjects where code='INF_GENERAL';
 insert into public.questions(subject_id,floor,question_text,option_a,option_b,option_c,option_d,difficulty,created_by)
 values(subject,3,'¿Cuál de estos componentes almacena datos aunque el computador esté apagado?','RAM','SSD','CPU','Caché','easy',author_id) returning id into q;
 insert into public.question_keys values(q,'B','Un SSD utiliza almacenamiento no volátil.');
 insert into public.questions(subject_id,floor,question_text,option_a,option_b,option_c,option_d,difficulty,created_by)
 values(subject,3,'¿Qué dispositivo conecta varios equipos dentro de una red local?','Monitor','Switch','Teclado','Impresora','easy',author_id) returning id into q;
 insert into public.question_keys values(q,'B','Un switch conecta equipos dentro de una red local.');
 insert into public.questions(subject_id,floor,question_text,option_a,option_b,option_c,option_d,difficulty,created_by)
 values(subject,3,'¿Qué lenguaje consulta bases de datos relacionales?','SQL','HTML','CSS','PNG','easy',author_id) returning id into q;
 insert into public.question_keys values(q,'A','SQL permite consultar datos relacionales.');
end $$;
