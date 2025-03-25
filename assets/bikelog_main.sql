create table if not exists owners (
    num integer primary key autoincrement,
    del integer not null default 0,
    name text not null,
    comment text
);

create table if not exists types (
    num integer primary key autoincrement,
    del integer not null default 0,
    name text not null,
    comment text
);

create table if not exists events (
    num integer primary key autoincrement,
    del integer not null default 0,
    name text not null,
    comment text
);

create table if not exists bikes (
    num integer primary key autoincrement,
    del integer not null default 0,
    owner integer,
    brand text,
    model text,
    type integer,
    serialnum text,
    buydate integer,
    photo text,
    foreign key (owner) references owners(num),
    foreign key (type) references types(num)
);

create table if not exists actions (
    num integer primary key autoincrement,
    del integer not null default 0,
    bike integer,
    date integer,
    event integer,
    price real,
    comment text,
    foreign key (bike) references bikes(num)
    foreign key (event) references events(num)
);

