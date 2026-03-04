@ECHO OFF
cd C:\Users\user\Downloads\homeworks\hw9-group9\
echo "# x.1: git diff-p" >> C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz\CHANGELOG.md
git diff -p >> C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz\CHANGELOG.md
echo "" >> C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz\CHANGELOG.md
cd C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz
..\compile.bat
echo "# x.2: test.bat" >> CHANGELOG.md
..\test.bat >> C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz\CHANGELOG.md