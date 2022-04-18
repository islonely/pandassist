module main

import htmlbuilder
import time

// Gender represents all available genders for the human race.
enum Gender {
	male = 0
	female = 1
}

// Student represents a row from the `students` table in the database.
struct Student {
	id     int
	name   string
	gender Gender = .female
}

// Teacher represents a row from the `teachers` table in the databse.
struct Teacher {
	id       int
	username string
	name     string
	email    string
	phone    string
	dob      time.Time
	students []Student
}

// html returns the html code for an array of Student
fn (students []Student) html() string {
	mut str := ''
	for s in students {
		str += s.html() + '\n'
	}
	return str
}

// html returns the html code for an individual Student
fn (student Student) html() string {
	name := student.name.replace(' ', '-')
	gender := student.gender.str()
	mut bldr := htmlbuilder.new_builder()
	bldr.open_tag('a', {
		'href':  '/students/$name'
		'class': 'student flex items-center'
	})
	bldr.open_tag('img', {
		'src':   '/assets/img/profile-default-${gender}.png'
		'class': 'rounded-full h-12 pr-1'
	})
	bldr.open_tag('h4', {
		'class': 'pt-2 leading-tight mb-2'
		'style': 'font-weight: bold'
	})
	bldr.write_string(student.name)
	bldr.close_all_tags()
	return bldr.str()
}