// executing path
HostingEnvironment.ApplicationPhysicalPath
AppDomain.CurrentDomain.BaseDirectory
Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location)


when running in win service:
Path.Combine(AppContext.BaseDirectory, "yourfile.txt")