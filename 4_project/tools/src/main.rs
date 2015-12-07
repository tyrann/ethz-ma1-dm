use std::env;
use std::io;
use std::fs;
use std::process;

use std::io::{
    Write,
    Read,
    Error,
    ErrorKind,
};

use std::iter::{
    Iterator,
};

/// We use the simple 'python' shell command to run the python scripts.
/// This also means we assume that the client of this program has a valid
/// python installation and the scripts are compatible with that python
/// installation.
const PYTHON: &'static str = "python";

/// Instead of using an in code solution to sort our results, we use an
/// external solution which is available on all unix systems. The 'sort'
/// command will perform lexical sorting on our 
const SORTER: &'static str = "sort";

/// Type alias for our own result type. Since all our errors that can occur
/// are io errors, we alias our result type to the io result type and return
/// io errors directly.
type Result<T> = io::Result<T>;

/*****************************************************************************************/

fn spawn_sort() -> Result<process::Child> {
    process::Command::new(SORTER)
        .stdin(process::Stdio::piped())
        .stdout(process::Stdio::piped())
        .spawn()
}

fn spawn_python(script: &str) -> Result<process::Child> {
    process::Command::new(PYTHON)
        .arg(script)
        .stdin(process::Stdio::piped())
        .stdout(process::Stdio::piped())
        .spawn()
}

fn stop_child(child: process::Child) -> Result<String> {
    let output  = try!(child.wait_with_output());
    let stdout  = output.stdout;

    match String::from_utf8(stdout) {
        Err(_)  => Err(Error::new(ErrorKind::Other, "Could not read as string.")),
        Ok(out) => Ok(out),
    }
}

fn write_sample<'a>(stdin: &mut process::ChildStdin, sample: &'a str) -> Result<()> {
    try!(stdin.write_all(sample.as_bytes()));
    try!(stdin.write_all("\n".as_bytes()));

    Ok(())
}

fn write_all_data<'a, T>(child: &mut process::Child, data: T) -> Result<()>
    where T: IntoIterator<Item = &'a str> {
    let mut stdin = try!(
        child
        .stdin
        .as_mut()
        .ok_or(Error::new(ErrorKind::Other, "Could not access stdin."))
    );

    for sample in data {
        try!(write_sample(&mut stdin, sample));
    } 

    Ok(())
}

fn write_all_balanced<'a, T>(children: &mut Vec<process::Child>, data: T) -> Result<()>
    where T: IntoIterator<Item = &'a str> {
        let mut stdins = Vec::new();

        unsafe {
            for index in 0..children.len() {
                let mut child = &mut *(children.get_unchecked_mut(index) as *mut process::Child);
                let stdin = try!(child.stdin
                    .as_mut()
                    .ok_or(Error::new(ErrorKind::Other, "Could not access stdin.")));

                stdins.push(stdin);
            }
        }

        // Write the actual data by going through the standard inputs in round robin fashion.
        // For this we need to extract an iterator from our data and keep track of an additional
        // mutable index.
        let mut data  = data.into_iter();
        let mut index = 0;

        while let Some(v) = data.next() {
            try!(stdins[index%children.len()].write_all(v.as_bytes()));
            try!(stdins[index%children.len()].write_all("\n".as_bytes()));
            index = index + 1;
        };

        Ok(())
}

fn load_from_file(path: &str) -> Result<String> {
    let mut buffer = String::new();
    let mut file   = try!(fs::File::open(&path));

    try!(file.read_to_string(&mut buffer));

    Ok(buffer)
}

/*****************************************************************************************/

/// The map reduce trait provides the most simple functionality needed to
/// run the map reduce algorithm.
///
/// # Interface
///
/// The interface defined by the MapReduce trait is sufficiently generic to
/// account for multiple different approachs to implementing it. The data that
/// is written into our standard inputs and outputs can come from any arbitrary
/// source that can provide strings. The only restriction is that the source 
/// must be iterable.
///
/// # Return values
///
/// The return value is always a string containing the values read from the standard
/// output. How these values are then handled is not defined by the mapreduce itself, but
/// rather by the client of the mapreduce object.
trait MapReduce {
    fn map<'a, T: IntoIterator<Item = &'a str>>(&self, data: T) -> Result<String>;
    fn sort<'a, T: IntoIterator<Item = &'a str>>(&self, data: T) -> Result<String>;
    fn reduce<'a, T: IntoIterator<Item = &'a str>>(&self, data: T) -> Result<String>;
}

/// The data handler trait is used to store and load results of successive map
/// reduce computations. 
///
/// # Interface
///
/// It is not possible to load arbitrary intermediate results using the data handler.
/// The store and load functions always refer to the latest result. That is, after storing
/// a result, load will return handles to said result until a new result is stored.
trait DataHandler {
    fn store(&mut self, data: &str) -> Result<()>;
    fn load(&mut self) -> Result<String>;
}

/// Adds a function 'run', which allows arbitrary structs that are instances of MapReduce
/// as well as DataHandler to be run to completion.
///
/// # Steps
///
/// The 'run' function is the equivalent of calling each of the map, sort and reduce
/// functions individually and storing their results directly after callign the respective
/// function. The method does not take a shortcut. The values are loaded again after being
/// stored.
///
/// # Note
///
/// Since the values are loaded again every time, you might want to consider adjusting the
/// method when implementing the trait. For example, loading large amounts of data from files,
/// just after saving them will cause a lot of slow down. Also note that we introduce a new 
/// scope after each operation, which cleanrs the memory from previous values.
trait Runnable: MapReduce + DataHandler {
    fn run<'a, T: IntoIterator<Item = &'a str>>(&mut self, data: T) -> Result<String> {
        {
            let data = try!(self.map(data));
            try!(self.store(&data));
        }

        {
            let data = try!(self.load());
            let data = data.lines();
            let data = try!(self.sort(data));
            try!(self.store(&data));
        }

        {
            let data = try!(self.load());
            let data = data.lines();
            let data = try!(self.reduce(data));
            try!(self.store(&data));
        }

        match self.load() {
            Ok(ref v) => Ok(v.clone()),
            Err(_)    => Err(Error::new(ErrorKind::Other, "Could not finish run.")),
        }
    }
}

#[derive(Debug)]
enum Phase {
    Map,
    Sort,
    Reduce,
    Idle,
}

/*****************************************************************************************/

#[derive(Debug)]
struct Simple {
    mapped:  Option<String>,
    sorted:  Option<String>,
    reduced: Option<String>,

    mapper:  String,
    reducer: String,
}

impl Simple {
    fn new(mapper: &str, reducer: &str) -> Simple {
        Simple {
            mapped:     None,
            sorted:     None,
            reduced:    None,
            mapper:     mapper.to_string(),
            reducer:    reducer.to_string(),
        }
    }
}

impl Runnable for Simple {}

impl MapReduce for Simple {
    fn map<'a, T: IntoIterator<Item = &'a str>>(&self, data: T) -> Result<String> {
        let mut child = try!(spawn_python(&self.mapper));
        
        match write_all_data(&mut child, data) {
            Ok(_)  => (),
            Err(e) => return Err(e),
        };

        stop_child(child)
    }

    fn sort<'a, T: IntoIterator<Item = &'a str>>(&self, data: T) -> Result<String> {
        let mut child = try!(spawn_sort());

        match write_all_data(&mut child, data) {
            Ok(_)  => (),
            Err(e) => return Err(e),
        };

        stop_child(child)
    }

    fn reduce<'a, T: IntoIterator<Item = &'a str>>(&self, data: T) -> Result<String>{
        let mut child = try!(spawn_python(&self.reducer));

        match write_all_data(&mut child, data) {
            Ok(_)  => (),
            Err(e) => return Err(e),
        };

        stop_child(child)
    }
}

impl DataHandler for Simple {
    fn store(&mut self, data: &str) -> Result<()> {
        // The idea is simple, find the first that has not been assigned yet and
        // assign the data to that. Otherwise, assign the data to the reduced data.
        let data = data.to_string();

        if      let None = self.mapped { self.mapped = Some(data); }
        else if let None = self.sorted { self.sorted = Some(data); }
        else { self.reduced = Some(data); }
        
        Ok(())
    }

    fn load(&mut self) -> Result<String> {
        let ref result = self.reduced.as_ref()
            .or(self.sorted.as_ref())
            .or(self.mapped.as_ref())
            .or(None);

        match *result {
            None    => Err(Error::new(ErrorKind::Other, "Loaded unknown value.")),
            Some(s) => Ok(s.clone()),
        }
    }
}

/*****************************************************************************************/

#[derive(Debug)]
struct Parallel {
    mapper_out:     String,
    sorter_out:     String,
    reducer_out:    String,

    mapper:         String,
    reducer:        String,

    cores:          usize,
    phase:          Phase,
}

impl Parallel {
    fn new(
        mapper_out:     &str, 
        sorter_out:     &str, 
        reducer_out:    &str, 
        mapper:         &str, 
        reducer:        &str, 
        cores:          usize) -> Parallel {
        Parallel {
            mapper_out:     mapper_out.to_string(),
            sorter_out:     sorter_out.to_string(),
            reducer_out:    reducer_out.to_string(),
            mapper:         mapper.to_string(),
            reducer:        reducer.to_string(),
            cores:          cores,
            phase:          Phase::Idle,
        }
    }

    fn with_default_files(mapper: &str, reducer: &str, cores: usize) -> Parallel {
        let mapper  = mapper.to_string();
        let reducer = reducer.to_string();

        Parallel {
            sorter_out:     "sorter_out".to_string(),
            mapper_out:     mapper.clone() + ".out",
            reducer_out:    reducer.clone() + ".out",

            mapper:         mapper,
            reducer:        reducer,

            cores:          cores,
            phase:          Phase::Idle,
        }
    }
}

impl Runnable for Parallel {}

impl MapReduce for Parallel {
    fn map<'a, T: IntoIterator<Item = &'a str>>(&self, data: T) -> Result<String> {
        let mut children = Vec::new();

        // First of all, we need to spawn enough child processes to cover the
        // client request. That is, we spawn as many child processes as the client
        // requested and do not check whether that makes actual sense.
        for _ in 0..self.cores {
            children.push(try!(spawn_python(&self.mapper)));
        }

        match write_all_balanced(&mut children, data) {
            Ok(_)  => (),
            Err(e) => return Err(e),
        };

        let mut buffer = String::new();
        // Now, gather all the output from all our children. To do so, we use a mutable
        // string as a buffer and continuously append the results reported by the child
        // processes.
        while let Some(child) = children.pop() {
            let output = try!(stop_child(child));
            let string = &output;
            buffer.push_str(string);
        }

        Ok(buffer)
    }

    fn sort<'a, T: IntoIterator<Item = &'a str>>(&self, data: T) -> Result<String> {
        let mut child = try!(spawn_sort());

        match write_all_data(&mut child, data) {
            Ok(_)  => (),
            Err(e) => return Err(e),
        };

        stop_child(child)
    }

    fn reduce<'a, T: IntoIterator<Item = &'a str>>(&self, data: T) -> Result<String> {
        let mut children = Vec::new();

        // First of all, we need to spawn enough child processes to cover the
        // client request. That is, we spawn as many child processes as the client
        // requested and do not check whether that makes actual sense.
        for _ in 0..1 {
            children.push(try!(spawn_python(&self.reducer)));
        }

        match write_all_balanced(&mut children, data) {
            Ok(_)  => (),
            Err(e) => return Err(e),
        };

        let mut buffer = String::new();
        // Now, gather all the output from all our children. To do so, we use a mutable
        // string as a buffer and continuously append the results reported by the child
        // processes.
        while let Some(child) = children.pop() {
            let output = try!(stop_child(child));
            let string = &output;
            buffer.push_str(string);
        }

        Ok(buffer)
    }
}

impl DataHandler for Parallel {
    fn store(&mut self, data: &str) -> Result<()> {
        self.phase = match self.phase {
            Phase::Idle => Phase::Map,
            Phase::Map  => Phase::Sort,
            _           => Phase::Reduce,
        };

        let ref target = match self.phase {
            Phase::Map     => &self.mapper_out,
            Phase::Sort    => &self.sorter_out,
            Phase::Reduce  => &self.reducer_out,
            _              => return Err(Error::new(ErrorKind::Other, "Unknown phase.")),
        };

        // Open a file in write-only mode, returns `io::Result<File>`
        let mut file = try!(fs::File::create(&target));

        // Write the `LOREM_IPSUM` string to `file`, returns `io::Result<()>`
        try!(file.write_all(data.as_bytes()));

        Ok(())
    }

    fn load(&mut self) -> Result<String> {
        let ref target = match self.phase {
            Phase::Map     => &self.mapper_out,
            Phase::Sort    => &self.sorter_out,
            Phase::Reduce  => &self.reducer_out,
            _              => return Err(Error::new(ErrorKind::Other, "Unknown phase.")),
        };


        // Open the path in read-only mode, returns `io::Result<File>`
        let mut file = try!(fs::File::open(&target));

        // Read the file contents into a string, returns `io::Result<usize>`
        let mut s = String::new();
        try!(file.read_to_string(&mut s));

        Ok(s)
    }
}

/*****************************************************************************************/

fn main() {
    let args: Vec<String> = env::args().collect();
    let mapper  = &args[1];
    let reducer = &args[2];

    let data    = match load_from_file(&args[3]) {
        Ok(file) => file,
        Err(_)   => panic!("Could not open data file!"),
    };

    let mut complex = Parallel::with_default_files(&mapper, &reducer, 8);

    match complex.run(data.lines()) {
        Err(_) => println!("Something went wrong!"),
        Ok(_)  => println!("Everything went fine!"),
    };
}