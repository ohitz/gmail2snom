gmail2snom
==========

The gmail2snom.pl script allows contacts exported from the Gmail
service to be imported into a Snom 870 phone.

It works for me and may serve as a starting point for other Snom
users.

Usage:

1. Export contacts on the Gmail website into "Google CSV" format.

2. Convert the contacts using this script: `./gmail2snom.pl google.csv snom.csv`

3. Import the contacts on the Snom 870 phone.
