# ftp to server
# anonymous login
# ftp try to log in
# username: ftp
# password: ftp, ftp123, ftpass, ftpass123, ftpassword, ftpassword123, pass, pass123, password, password123, else try anonymous
# run a command to ip/?cmd=<>
# do these commands to look at rwx access in the web directory
# if positive for any folder, inject malicious script for persistence
# inject malicious commands to break ftp
# - block port 21 and port 20 to the scoring engine
# - create a forced active and passive mode mismatch?
# - make FTP user's home directory inaccessible
# - mess with PAM authentication?
# - stop the FTP service
# - create a bunch of errors inside the config file
# - change the port
# - spin up another thing running on port 21
