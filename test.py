import pyodbc 
import os
import datetime
import time
from constants import  * 
import re
# Some other example server values are
# server = 'localhost\sqlexpress' # for a named instance
# server = 'myserver,port' # to specify an alternate port

#Function Definitions 
def get_file_list(files_path):

    files_name_list = []
    print(os.getcwd())
    if(os.path.isdir(files_path) == True) :
        try:
            for root, directories, files in os.walk(files_path , topdown=False) :
                for file in files:
                    files_name_list.append(root + f'/{file}')
        except Exception as e :
            print(e)
    else:
        print('Not a directory')
    return files_name_list
       
    
def get_server_database_details(filename):
        #file = open(filename, 'r')
        
        print(filename)
        
        #file = open(filename , 'r')
        
        
        
        with open(filename, "r") as f:
            names_list = [line.strip() for line in f if line.strip()]
        #print(names_list)
        
        server_name = str(re.sub('[^A-Za-z0-9]+', '', names_list[0].split(' ')[-1]))
        database_name = str(re.sub('[^A-Za-z0-9]+', '', names_list[1].split(' ')[-1]))
        #print(server_name , database_name)
        
        return server_name , database_name

def run_sql_file(filename , server_name, database_name):
        '''
        The function takes a filename and a connection as input
        and will run the SQL query on the given connection  
        '''
        
        server_name, database_name = get_server_database_details(filename)
        
        print(server_name, database_name)
        with open(filename) as f:
            sql_query = "".join(line for line in f if not line.isspace())
            
        print(sql_query)
            
        connection = pyodbc.connect(r'Driver={ODBC Driver 17 for SQL Server};Server='+str(server_name)+';Database='+str(database_name)+';Trusted_Connection=yes;')
        cursor = connection.cursor()
        cursor.execute(sql_query)    
        filename.close()
            
        
        
        #for row in cursor.fetchall():
        #    print('row = %r' % (row,))

        end = time.time()
        #print("Time elapsed to run the query:")
        #print( str((end - start)*1000) + ' ms')
        
#cnxn = pyodbc.connect(r'Driver={SQL Server};Server=DSDEVSQL01;Database=PostTripDM;Trusted_Connection=yes;')
        
       
        #connection = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)        


    
def main():   
        
        files_name_list = get_file_list(path)
        
        suff = '.sql'
        files_name_list_updated = [ele for ele in files_name_list if ele.endswith(suff)] 
        print(files_name_list_updated)
        
        for i in files_name_list_updated:
            try:
                server_name, database_name = get_server_database_details(i)
                
                try :
                    run_sql_file(i , server_name, database_name )
 
                except  Exception as e :
                    print(e)
                
            except:
                pass
            break
                            
        print('Connection is close now . YOU ARE DONE . TAKE A REST')
       
    
    
if __name__ == "__main__":
        main()
        