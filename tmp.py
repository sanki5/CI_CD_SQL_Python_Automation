import pyodbc
cnxn = pyodbc.connect(r'Driver={ODBC Driver 17 for SQL Server};Server=;Database={DSSBSSIS01};Trusted_Connection=yes;')
cursor = cnxn.cursor()
cursor.execute("SELECT top(5) * FROM dbo.CompanySequenceNumber")
for row in cursor.fetchall():
            print('row = %r' % (row))