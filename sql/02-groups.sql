-- In this simple example there is a 1-to-1 mapping of group to authorities (e.g. permisions)
insert into groups (id, group_name) values (1, 'USER');
insert into groups (id, group_name) values (2, 'ADMIN');

insert into group_authorities (group_id, authority) values (1, 'USER');
insert into group_authorities (group_id, authority) values (2, 'ADMIN');