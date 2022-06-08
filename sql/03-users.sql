-- populate users
insert into users (username, password, enabled, first_name, last_name, phone)
values ('user1@example.com',
        '{bcrypt}$2a$10$GRLdNijSQMUvl/au9ofL.eDwmoohzzS7.rmNSJZ.0FxO/BTk76klW', -- password
        true,
        'User',
        'One',
        '123-555-1234');
insert into users (username, password, enabled, first_name, last_name, phone)
values ('admin@example.com',
        '{bcrypt}$2a$10$GRLdNijSQMUvl/au9ofL.eDwmoohzzS7.rmNSJZ.0FxO/BTk76klW', -- password
        true,
        'Admin',
        'Istrator',
        '123-555-4567');

insert into users (username, password, enabled, first_name, last_name, phone)
values ('user2@example.com',
        '{scrypt}$e0801$lFhoTwfU4hAjfIt0W+jNop6H2IJTGfUg4d/Z2yi0eUeQxwZ6r9R/Hr86wOuuXhqi7CRp0ErqxGfGqhetL44O6A==$NcwvQOopkOZFp723IbMdcr9zfaodHNNBjI07DwxaXjA=', -- password
        true,
        'User2',
        'Two',
        '123-555-4321');

-- assign groups to users
insert into group_members (username, group_id) values ('user1@example.com', 1);
insert into group_members (username, group_id) values ('user2@example.com', 1);
insert into group_members (username, group_id) values ('admin@example.com', 2);
insert into group_members (username, group_id) values ('admin@example.com', 1);
