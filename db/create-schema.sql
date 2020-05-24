-- begin transaction
begin;

-- create schemas
create schema forum_example;
create schema forum_example_private;

-- create extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- create the person table
create table forum_db.forum_example.person (
  id               uuid primary key default uuid_generate_v1mc(),
  first_name       text not null check (char_length(first_name) < 80),
  last_name        text check (char_length(last_name) < 80),
  about            text,
  created_at       timestamp default now()
);

-- create comments
comment on table forum_example.person is 'A user of the forum.';
comment on column forum_example.person.id is 'The primary unique identifier for the person.';
comment on column forum_example.person.first_name is 'The person’s first name.';
comment on column forum_example.person.last_name is 'The person’s last name.';
comment on column forum_example.person.about is 'A short description about the user, written by the user.';
comment on column forum_example.person.created_at is 'The time this person was created.';

-- create post topic
create type forum_example.post_topic as enum (
  'discussion',
  'inspiration',
  'help',
  'showcase'
);

-- create post table
create table forum_example.post (
  id               serial primary key,
  author_id        uuid not null references forum_example.person(id),
  headline         text not null check (char_length(headline) < 280),
  body             text,
  topic            forum_example.post_topic,
  created_at       timestamp default now()
);

comment on table forum_example.post is 'A forum post written by a user.';
comment on column forum_example.post.id is 'The primary key for the post.';
comment on column forum_example.post.headline is 'The title written by the user.';
comment on column forum_example.post.author_id is 'The id of the author user.';
comment on column forum_example.post.topic is 'The topic this has been posted in.';
comment on column forum_example.post.body is 'The main body text of our post.';
comment on column forum_example.post.created_at is 'The time this post was created.';

-- after schema creation and before function creation
alter default privileges revoke execute on functions from public;

-- composite type
create function forum_example.person_full_name(person forum_example.person) returns text as $$
  select person.first_name || ' ' || person.last_name;
$$ language sql stable;

comment on function forum_example.person_full_name(forum_example.person) is 'A person’s full name which is a concatenation of their first and last name.';

-- composite type post_summery
create function forum_example.post_summery(
  post forum_example.post,
  length int default 50,
  ommission text default '…'
) returns text as $$
  select case
    when post.body is null then null
    else substr(post.body, 0, length) || ommission
  end
$$ language sql stable;

comment on function forum_example.post_summery(forum_example.post, int, text) is 'A truncated version of the body for summaries.';

-- get latest post function
create function forum_example.person_latest_post(person forum_example.person) returns forum_example.post as $$
  select post.*
  from forum_example.post as post
  where post.author_id = person.id
  order by created_at desc
  limit 1
$$ language sql stable;

comment on function forum_example.person_latest_post(forum_example.person) is 'Get’s the latest post written by the person.';

-- search posts function
create function forum_example.search_posts(search text) returns setof forum_example.post as $$
  select post.*
  from forum_example.post as post
  where position(search in post.headline) > 0 or position(search in post.body) > 0
$$ language sql stable;

comment on function forum_example.search_posts(text) is 'Returns posts containing a given search term.';

-- these fields should have been in the schema
alter table forum_example.person add column updated_at timestamp default now();
alter table forum_example.post add column updated_at timestamp default now();

-- set updated at function which returns a trigger
-- NEW is the new entryname
create function forum_example_private.set_updated_at() returns trigger as $$
begin
  new.updated_at := current_timestamp;
  return new;
end;
$$ language plpgsql;

-- bind to person person table
create trigger person_updated_at before update
  on forum_example.person
  for each row
  execute procedure forum_example_private.set_updated_at();

-- bind to post table
create trigger post_updated_at before update
  on forum_example.post
  for each row
  execute procedure forum_example_private.set_updated_at();

-- creating the person_account table
create table forum_example_private.person_account (
  person_id        uuid primary key references forum_example.person(id) on delete cascade,
  email            text not null unique check (email ~* '^.+@.+\..+$'),
  password_hash    text not null
);

comment on table forum_example_private.person_account is 'Private information about a person’s account.';
comment on column forum_example_private.person_account.person_id is 'The id of the person associated with this account.';
comment on column forum_example_private.person_account.email is 'The email address of the person.';
comment on column forum_example_private.person_account.password_hash is 'An opaque hash of the person’s password.';


-- register function
create function forum_example.register_person(
  first_name text,
  last_name text,
  email text,
  password text
) returns forum_example.person as $$
declare
  person forum_example.person;
begin
  insert into forum_example.person (first_name, last_name) values
    (first_name, last_name)
    returning * into person;

  insert into forum_example_private.person_account (person_id, email, password_hash) values
    (person.id, email, crypt(password, gen_salt('bf')));
  return person;
end;
$$ language plpgsql strict security definer;

comment on function forum_example.register_person(text, text, text, text) is 'Registers a single user and creates an account in our forum.';

-- Setting Roles
drop role if exists forum_example_postgraphile;
drop role if exists forum_example_anonymous;
drop role if exists forum_example_person;

create role forum_example_postgraphile login password 'password';
create role forum_example_anonymous;

-- just to be able to switch roles
grant forum_example_anonymous to forum_example_postgraphile;

-- this is your logged in user
create role forum_example_person;
grant forum_example_person to forum_example_postgraphile;

-- create your JWT token type
create type forum_example.jwt_token as (
  role text,
  person_id uuid,
  exp bigint
);

-- authenticate function
create function forum_example.authenticate(
  email text,
  password text
) returns forum_example.jwt_token as $$
declare
  account forum_example_private.person_account;
begin
  select a.* into account
  from forum_example_private.person_account as a
  where a.email = $1;

  if account.password_hash = crypt(password, account.password_hash) then
    return ('forum_example_person', account.person_id, extract(epoch from (now() + interval '2 days')))::forum_example.jwt_token;
  else
    return null;
  end if;
end;
$$ language plpgsql strict security definer;

comment on function forum_example.authenticate(text, text) is 'Creates a JWT token that will securely identify a person and give them certain permissions. This token expires in 2 days.';

-- get current logged in user function
create function forum_example.current_person() returns forum_example.person as $$
  select *
  from forum_example.person
  where id = nullif(current_setting('jwt.claims.person_id', true), '')::uuid
$$ language sql stable;

comment on function forum_example.current_person() is 'Gets the person who was identified by our JWT.';




grant usage on schema forum_example to forum_example_anonymous, forum_example_person;

grant select on table forum_example.person to forum_example_anonymous, forum_example_person;
grant update, delete on table forum_example.person to forum_example_person;

grant select on table forum_example.post to forum_example_anonymous, forum_example_person;
grant insert, update, delete on table forum_example.post to forum_example_person;
grant usage on sequence forum_example.post_id_seq to forum_example_person;

grant execute on function forum_example.person_full_name(forum_example.person) to forum_example_anonymous, forum_example_person;
grant execute on function forum_example.post_summery(forum_example.post, integer, text) to forum_example_anonymous, forum_example_person;
grant execute on function forum_example.person_latest_post(forum_example.person) to forum_example_anonymous, forum_example_person;
grant execute on function forum_example.search_posts(text) to forum_example_anonymous, forum_example_person;
grant execute on function forum_example.authenticate(text, text) to forum_example_anonymous, forum_example_person;
grant execute on function forum_example.current_person() to forum_example_anonymous, forum_example_person;

grant execute on function forum_example.register_person(text, text, text, text) to forum_example_anonymous;

alter table forum_example.person enable row level security;
alter table forum_example.post enable row level security;

create policy select_person on forum_example.person for select
  using (true);

create policy select_post on forum_example.post for select
  using (true);

create policy update_person on forum_example.person for update to forum_example_person
  using (id = nullif(current_setting('jwt.claims.person_id', true), '')::uuid);

create policy delete_person on forum_example.person for delete to forum_example_person
  using (id = nullif(current_setting('jwt.claims.person_id', true), '')::uuid);

--
create policy insert_post on forum_example.post for insert to forum_example_person
  with check (author_id = nullif(current_setting('jwt.claims.person_id', true), '')::uuid);

create policy update_post on forum_example.post for update to forum_example_person
  using (author_id = nullif(current_setting('jwt.claims.person_id', true), '')::uuid);

create policy delete_post on forum_example.post for delete to forum_example_person
  using (author_id = nullif(current_setting('jwt.claims.person_id', true), '')::uuid);

-- end transaction
commit;