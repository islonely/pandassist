module main

import mysql
import time
import toml

const (
	const_mysql_void_connection = mysql.Connection{
		host: '0.0.0.0'
		port: 0
	}
	const_mysql_username_max_len = 30
	const_mysql_name_max_len     = 80
	const_mysql_email_max_len    = 100
	const_mysql_password_max_len = 100
	const_mysql_phone_max_len    = 31
)

const (
	const_mysql_error_username_taken     = error('Selected username is already in use.')
	const_mysql_error_email_taken        = error('Selected email address is already in use.')
	const_mysql_error_username_gt_max    = error('Selected username exceeds character limit of $const_mysql_username_max_len .')
	const_mysql_error_name_gt_max        = error('Full name provided exceeds character limit of $const_mysql_name_max_len .')
	const_mysql_error_email_gt_max       = error('Selected email exceeds character limit of $const_mysql_email_max_len .')
	const_mysql_error_password_gt_max    = error('Password provided exceeds character limit of $const_mysql_password_max_len .')
	const_mysql_error_phone_gt_max       = error('Phone number provided exceeds character limit of $const_mysql_phone_max_len .')

	const_mysql_error_teacher_not_found  = error('No entry found in table `teachers` with matching id.')
	const_mysql_error_students_not_found = error('No entries found in table `teachers` with matching ids.')
)

// new_connection returns a new MySQL connection to the database
// found in config.toml
fn new_connection(config toml.Doc) mysql.Connection {
	return mysql.Connection{
		dbname: config.value('mysql.dbname').default_to('panda').string()
		host: config.value('mysql.host').default_to('127.0.0.1').string()
		port: u32(config.value('mysql.port').default_to(3306).int())
		username: config.value('mysql.username').default_to('').string()
		password: config.value('mysql.password').default_to('').string()
	}
}

// get_id_from_email connects to the database and fetches the id
// of the row with the provided email
fn (mut app App) get_id_from_email(email string) ?int {
	app.dbconn.connect() ?
	// closing the database is causing a RUNITIME ERROR: abort()
	// defer { app.dbconn.close() }

	query := 'SELECT id FROM teachers WHERE email=\'$email\';'
	res := app.dbconn.query(query) ?
	return if res.n_rows() == 0 {
		const_mysql_error_teacher_not_found
	} else {
		res.maps()[0]['id'].int()
	}
}

// get_teacher creates a Teacher object from the provided id
fn (mut app App) get_teacher(id int) ?Teacher {
	app.dbconn.connect() ?
	defer {
		app.dbconn.close()
	}

	query := 'SELECT * FROM teachers WHERE id=$id;'
	res := app.dbconn.query(query) ?
	if res.n_rows() == 0 {
		return const_mysql_error_teacher_not_found
	}

	row := res.maps()[0]
	ids_str := row['students'].split(',')
	mut ids := []int{cap: ids_str.len}
	for i in ids_str {
		ids << i.trim_space().int()
	}
	return Teacher{
		id: row['id'].int()
		username: row['username']
		name: row['full_name']
		email: row['email']
		dob: time.unix(row['account_birth'].i64())
		phone: row['phone']
		students: app.get_students(ids) or {
			println(err.msg())
			[]Student{}
		}
	}
}

// get_students returns an array of Student from the provided ids
fn (mut app App) get_students(ids []int) ?[]Student {
	app.dbconn.connect() ?
	defer {
		app.dbconn.close()
	}

	if ids.len <= 0 {
		return []Student{}
	}

	mut query := 'SELECT * FROM students WHERE id IN (' + ids[0].str()
	if ids.len > 1 {
		for i := 1; i < ids.len; i++ {
			query += ', ' + ids[i].str()
		}
	}
	query += ');'

	res := app.dbconn.query(query) ?
	if res.n_rows() == 0 {
		return const_mysql_error_students_not_found
	}

	mut students := []Student{cap: int(res.n_rows())}
	for row in res.maps() {
		students << Student{
			id: row['id'].int()
			name: row['name']
			gender: Gender(row['gender'].int())
		}
	}
	return students
}
