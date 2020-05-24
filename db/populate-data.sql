begin;

insert into forum_example.person (id, first_name, last_name, about, created_at) values
  ('28b4e6df-3305-4b4f-928f-3fc015916a7b', 'Sara', 'Powell', null, '2015-07-03T14:11:30Z'),
  ('3d26847b-0410-4998-82c1-5138c5712033', 'Andrea', 'Fox', null, '1999-04-04T21:21:42Z'),
  ('3155e764-3f67-4855-9a02-cc062de54ea0', 'Stephen', 'Banks', null, '2003-12-09T04:39:10Z');
-- test
insert into forum_example_private.person_account (person_id, email, password_hash) values
  ('28b4e6df-3305-4b4f-928f-3fc015916a7b', 'spowell0@noaa.gov', '$2a$06$.Ryt.S6xCN./QmTx3r9Meu/nsk.4Ypfuj.o9qIqv4p3iipCWY45Bi'), -- Password: 'iFbWWlc'
  ('3d26847b-0410-4998-82c1-5138c5712033', 'afox1@npr.org', '$2a$06$FS4C7kwDs6tSrrjh0TITLuQ/pAjUHuCH0TBukHC.2m5n.Z1HxApRO'), -- Password: 'fjHtKk2FxCh0'
  ('3155e764-3f67-4855-9a02-cc062de54ea0', 'sbanks2@blog.com', '$2a$06$i7AoCg3pbAOmf8J2w/lGpukUfDuRdfyUrR/mN7I0x.AYZb3Ak6DYS'); -- Password: '3RLdPN9'

insert into forum_example.post (id, author_id, headline, body, topic) values
  (1,'3155e764-3f67-4855-9a02-cc062de54ea0','lacinia orci', 'Lorem ipsum', 'inspiration'),
  (2,'3d26847b-0410-4998-82c1-5138c5712033','feugiat.', 'Lorem ipsum', 'showcase'),
  (3,'3d26847b-0410-4998-82c1-5138c5712033','volutpat.', 'Lorem ipsum', 'discussion'),
  (4,'3d26847b-0410-4998-82c1-5138c5712033','libero. Donec consectetuer', 'Lorem ipsum', 'showcase'),
  (5,'3d26847b-0410-4998-82c1-5138c5712033','egestas. Aliquam fringilla', 'Lorem ipsum', 'showcase'),
  (6,'3155e764-3f67-4855-9a02-cc062de54ea0','Sed neque.', 'Lorem ipsum', 'showcase'),
  (7,'3155e764-3f67-4855-9a02-cc062de54ea0','commodo', 'Lorem ipsum', 'showcase'),
  (8,'3155e764-3f67-4855-9a02-cc062de54ea0','enim.', 'Lorem ipsum', 'showcase'),
  (9,'3155e764-3f67-4855-9a02-cc062de54ea0','magna', 'Lorem ipsum', 'help'),
  (10,'3d26847b-0410-4998-82c1-5138c5712033','non arcu.','Lorem ipsum', 'help');

commit;