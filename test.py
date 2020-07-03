import pyodbc 
import os
import datetime
import time
from constants import  * 
# Some other example server values are
# server = 'localhost\sqlexpress' # for a named instance
# server = 'myserver,port' # to specify an alternate port

#Function Definitions 
def run_sql_file(filename, connection):
        '''
        The function takes a filename and a connection as input
        and will run the SQL query on the given connection  
        '''
        start = time.time()
        
        file = open(filename, 'r')
        sql = s = " ".join(file.readlines())
        print( "Start executing: " + filename + " at " + str(datetime.datetime.now().strftime("%Y-%m-%d %H:%M")) + "\n" + sql )
        cursor = connection.cursor()
        cursor.execute(sql)    
        
        for row in cursor.fetchall():
            print('row = %r' % (row,))

        end = time.time()
        print("Time elapsed to run the query:")
        print( str((end - start)*1000) + ' ms')
        
        
def main():    

        connection = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
        cursor = connection.cursor()
        files = os.listdir(path)

        for root, directories, files in os.walk(path, topdown=False):
            for name in files:
                    
                    print(f'Script Started for SQL file Executing :: {name} \n')
                    try :
                        #Function Call 
                        run_sql_file(os.path.join(root, name), connection)    
                        print(f'Execution is done for SQL File :: {name} \n')
                    except Exception as e :
                        print(e)
                
            connection.close()
            print('Connection is close now . YOU ARE DONE . TAKE A REST')
       
if __name__ == "__main__":
        main()
        
