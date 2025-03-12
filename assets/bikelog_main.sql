create table if not exists owners (
    num integer primary key autoincrement,
    name text not null
);

create table if not exists types (
    num integer primary key autoincrement,
    name text not null
);

create table if not exists events (
    num integer primary key autoincrement,
    name text not null
);

create table if not exists bikes (
    num integer primary key autoincrement,
    owner integer,
    brand text,
    model text,
    type integer,
    serialnum text,
    buydate text,
    photo text,
    foreign key (owner) references owners(num),
    foreign key (type) references types(num)
);

create table if not exists actions (
    num integer primary key autoincrement,
    bike integer,
    date text,
    event integer,
    price real,
    comment text,
    foreign key (bike) references bikes(num)
    foreign key (event) references events(num)
);

