from distutils.core import setup, Extension

setup(
	name = "gps",
	version = @VERSION@,
	description = 'Python libraries for the gpsd service daemon',
	url = @URL@,
	author = 'the GPSD project',
	author_email = @EMAIL@,
	license = "BSD",
	packages = ['gps'],
)
