drop database marcelo;
create database marcelo;

\c marcelo

create table users (
    id varchar primary key,
    password varchar,
    name varchar,
    email varchar,
    role varchar, -- 'admin' | 'user'
    photo varchar,
    created timestamptz
);

create table polls (
    id serial primary key,
    user_id varchar references users on update cascade on delete cascade,
    title varchar,
    body text,
    created timestamptz
);

create table poll_options (
    id serial primary key,
    poll_id int references polls on update cascade on delete cascade,
    name varchar
);

create table poll_votes (
    user_id varchar references users on update cascade on delete cascade,
    poll_option_id int references poll_options
        on update cascade on delete cascade,
    created timestamptz,
    primary key (user_id, poll_option_id)
);

create table posts (
    id serial primary key,
    root_post_id int references posts on update cascade on delete cascade,
    post_id int references posts on update cascade on delete cascade,
    user_id varchar references users on update cascade on delete cascade,
    title varchar,
    body text,
    section varchar, -- idea | law
    created timestamptz,
    updated timestamptz
);
