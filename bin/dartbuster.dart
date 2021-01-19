import 'dart:io';
import 'dart:math';
import 'dart:isolate';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'user-agents.dart';

// Main
const version = '1.0.2';


// CLI colors
class C {
  final _ = '\u001b[0m';
  final p = '\u001b[38;5;204m';
  final o = '\u001b[38;5;208m';
  final b = '\u001b[38;5;295m';
  final c = '\u001b[38;5;299m';
  final g = '\u001b[38;5;47m';
  final r = '\u001b[38;5;1m';
  final y = '\u001b[38;5;226m';
}
final c = C();

// Handle error messages
void errorMessage(msg, {e=null}) {
  print('${c.r}[-]${c._} $msg');
  e != null ? print('    ${c.o}Stacktrace:${c._} $e') : null;
  exit(1);
}

// File name and directory path
final filename = Platform.script.toString().split('/').removeLast();
final working_dir = Platform.script.toString().replaceFirst('file://','').substring(0,Platform.script.toString().replaceFirst('file://','').length-filename.length);
// const working_dir = '/opt/dartbuster';


const commands = [
  {
    'name':['scan'],
    'parameter':null,
    'description':'Primary command for scanning.',
    'usage':['scan -u https://example.com/'],
    'default':null
  },
  {
    'name':['list'],
    'parameter':null,
    'description':'Prints available word and extensions lists.',
    'usage':['list'],
    'default':null
  },
  {
    'name':['useragents'],
    'parameter':null,
    'description':'Prints available useragents.',
    'usage':['useragents'],
    'default':null
  },
  {
    'name':['-h','--help','help'],
    'parameter':null,
    'description':'Prints this help screen.',
    'usage':['-h'],
    'default':null
  },
];
const flags = [
  {
    'name':['-u','--url'],
    'parameter':'<url/host>',
    'description':'Specify a url / host to fuzz.',
    'usage':['-u https://google.com'],
    'default':null
  },
  {
    'name':['-w','--wordlist'],
    'parameter':'<name/filepath>',
    'description':'Specify a wordlist to use, supports built in and custom wordlists.',
    'usage':['-w directory-list-lowercase-2.3-big.txt','-w /path/to/wordlist.txt'],
    'default':'default.txt'
  },
  {
    'name':['-e','--extensions'],
    'parameter':'<extensions/filepath>',
    'description':'Specify an extensions list to use, supports built in and custom values. Custom values must be comma delimited no spaces',
    'usage':['-e T','-e .html,.js,.php,.aspx'],
    'default':'tiny'
  },
  {
    'name':['-U','--useragent'],
    'parameter':'<id/custom>',
    'description':'Specify user agent, supports built in and custom user agents. For custom UAs escape space characters with "\".',
    'usage':['-U 1','-U Internet\\ Browser\\ Version\\ 10'],
    'default':'rotate'
  },
  {
    'name':['-t','--timeout'],
    'parameter':'<integer>',
    'description':'Specify max timeout time for a request in seconds.',
    'usage':['-t 30'],
    'default':'5'
  },
  {
    'name':['-T','--threads'],
    'parameter':'<integer>',
    'description':'Specify threadcount.',
    'usage':['-T 68'],
    'default':'50'
  },
  {
    'name':['-d','--delay'],
    'parameter':'<integer>',
    'description':'Specify delay between requests in seconds. Make sure to take threading into consideration.',
    'usage':['-d 5'],
    'default':'0'
  },
  {
    'name':['-o','--output'],
    'parameter':'<filepath>',
    'description':'Specify an output file, if file does not exist one will be created.',
    'usage':['-o output.txt'],
    'default':null
  },
  {
    'name':['-404'],
    'parameter':null,
    'description':'Include 404 responses in results and output.',
    'usage':['-404'],
    'default':null
  },
  {
    'name':['-v','--verbosity'],
    'parameter':null,
    'description':'Increases verbosity of the program by printing out error messages such as timeout requests and redirect loops.',
    'usage':['-v'],
    'default':null
  },
  {
    'name':['-c','--cookies'],
    'parameter':'<cookie(s)>',
    'description':'Specify raw cookie data.',
    'usage':['-c requestid=amVzdXMgbG92ZXMgeW91;','-c user=admin;pass=1234569;'],
    'default':null
  },
];










// Segments a list into equal parts
List segment(list, size) {
  var len = list.length;
  var chunks = [];

  for(var i = 0; i< len; i+= size) {    
    var end = (i+size<len)?i+size:len;
    chunks.add(list.sublist(i,end));
  }
  return chunks;
}

dynamic parseFlags(List<String> args, Map flag, {bool has_value = true}) {
  for (var i = 0; i < args.length; i++) {
    for (var prefix in flag['name']) {
      if (prefix == args[i]) {
        if (has_value) {
          try {
            return args[i+1];
          } catch (e) {
            return null;
          }
        } else {
          return true;
        }
      } else {
      }
    }
  }
  return flag['default'];
}

void list() {
  print('${c.y}${c.y}[*]${c.o} Installed Word Lists${c._}');
  print('${c.y}${c.y}[*]${c.o} Length   | Word list name${c._}');
  Directory(working_dir+'wordlists').listSync().forEach((e) {
    print('${c.g}[+]${c._} ${File(e.path.toString()).readAsLinesSync().length.toString().padRight(8)} ${c.o}|${c._} ${e.path.replaceFirst(working_dir+'wordlists/','')}');
  });
  print('${c.y}${c.y}[*]${c._} To install a wordlist place your wordlist file in ${c.o}${Directory(working_dir+'wordlists').path}${c._} and ensure entries are newline delimited.\n');

  print('${c.y}${c.y}[*]${c.o} Installed Extensions Lists${c._}');
  print('${c.y}${c.y}[*]${c.o} Length   | Extension list name${c._}');
  Directory(working_dir+'extensions').listSync().forEach((e) {
    print('${c.g}[+]${c._} ${File(e.path.toString()).readAsLinesSync().length.toString().padRight(8)} ${c.o}|${c._} ${e.path.replaceFirst(working_dir+'extensions/','')}');
  });
  print('${c.y}${c.y}[*]${c._} To install a wordlist place your wordlist file in ${c.o}${Directory(working_dir+'extensions').path}${c._} and ensure entries are newline delimited.');
}

void agents() {
  print('${c.y}ID | User Agent');
  for (var i = 0; i < user_agents.length; i++) {
    print('${c.g}${i.toString().padRight(2)}${c.y} |${c._} ${user_agents[i]}');
  }
}

void help() {
  print("""${c.o}
________              _____     ________              _____
___  __ \\_____ _________  /_    ___  __ )___  __________  /_____________
__  / / /  __ `/_  ___/  __/    __  __  |  / / /_  ___/  __/  _ \\_  ___/
_  /_/ // /_/ /_  /   / /_      _  /_/ // /_/ /_(__  )/ /_ /  __/  /
/_____/ \\__,_/ /_/    \\__/      /_____/ \\__,_/ /____/ \\__/ \\___//_/
              ${c.y}>>>>>>>_____________________\\`-._                       ${c.c}v:$version
              ${c.y}>>>>>>>                     /.-'""");
  print('${c.b}Author:${c.g} Gray   ${c.b}Website:${c.g} https://lambda.black/   ${c.b}Github:${c.g} https://github.com/GrayWasTaken');
  print('\n${c.o}Commands:');
  for (var x in commands) {
    var tmp = '${c.y}  ';
    for (var t in x['name']) {
      tmp+= '$t ${x['parameter'] != null ? x['parameter'].toString() + ' ' : ''}';
    }
    print(tmp);
    print('${c.b}    ${x['description']}');
    for (var t in x['usage']) {
      print('${c.c}    Usage: dartbuster $t');
    }
    x['default'] != null ? print('${c.c}    Default: ${x['default']}') : null;
  }
  print('\n${c.o}Scan Flags:');
  for (var x in flags) {
    var tmp = '${c.y}  ';
    for (var t in x['name']) {
      tmp+= '$t ${x['parameter'] != null ? x['parameter'].toString() + ' ' : ''}';
    }
    print(tmp);
    print('${c.b}    ${x['description']}');
    for (var t in x['usage']) {
      print('${c.c}    Usage: dartbuster $t');
    }
    x['default'] != null ? print('${c.c}    Default: ${x['default']}') : null;
  }
}












// Primary declarations
dynamic url;
dynamic word_list;
dynamic extensions;
dynamic user_agent;
dynamic timeout;
dynamic threads;
dynamic delay;
dynamic output;
dynamic show_404;
dynamic verbosity;
dynamic cookies;

Map<String, String> headers;
final ReceivePort rc = ReceivePort();



void main(List<String> arguments) async {
  // Parse Arguments
  try {
    if (arguments[0].toLowerCase() == 'scan') {
      // pass
    } else if (arguments[0].toLowerCase() == 'help' || arguments[0].toLowerCase() == '--help' || arguments[0].toLowerCase() == '-h') {
      help();
      exit(0);
    } else if (arguments[0].toLowerCase() == 'list') {
      try {
        list();
      } catch (e) {
        print(e);
      }
      exit(0);
    } else if (arguments[0].toLowerCase() == 'useragents') {
      agents();
      exit(0);
    } else {
      errorMessage('Invalid command specified, ${c.p}${arguments[0]}${c._}, for help run ${c.p}dartbuster help${c._}');
    }
  } catch (e) {
    help();
    exit(0);
  }

  // Parse Flags
  url = parseFlags(arguments, flags[0]);
  word_list = parseFlags(arguments, flags[1]);
  extensions = parseFlags(arguments, flags[2]);
  user_agent = parseFlags(arguments, flags[3]);
  timeout = parseFlags(arguments, flags[4]);
  threads = parseFlags(arguments, flags[5]);
  delay = parseFlags(arguments, flags[6]);
  output = parseFlags(arguments, flags[7]);
  show_404 = parseFlags(arguments, flags[9], has_value:false);
  verbosity = parseFlags(arguments, flags[9], has_value:false);
  cookies = parseFlags(arguments, flags[10]);


  // Parse and validate input
  // Check url (remove last char if /)
  try {
    if (url.substring(url.length-1) == '/') {
      url = url.substring(0, url.length-1);
    }
  } catch (e) {
    errorMessage('No url specified, for usage instructions refer to ${c.p}dartbuster --help${c._}.');
  }

  // Check word_list
  try {
    word_list = await File(word_list).readAsLines();
  } catch (e) {
    var found = false;
    Directory(working_dir+'wordlists').listSync().forEach((e) {
      if (e.path.replaceFirst(working_dir+'wordlists/','') == word_list) {
        word_list = File(e.path).readAsLinesSync();
        found = true;
      }
    });
    if (found == false) {
      errorMessage('Invalid word list / file path specified ${c.p}$word_list${c._}, to list available lists use ${c.p}dartbuster list${c._}');
    }
  }

  // Check extensions
  try {
    extensions = await File(working_dir+'extensions/'+extensions).readAsLines();
  } catch (e) {
    extensions = extensions != null ? extensions.split(',') : [];
  }
  extensions += ['']; // add no extension option to list

  // Check user_agent
  if (user_agent.toLowerCase() != 'rotate') {
    try {
      user_agent = user_agents[int.parse(user_agent)];
    } catch (e) {}
  }

  // // Check timeout
  try {
    timeout = int.parse(timeout);
  } catch (e) {
    errorMessage('Invalid timeout specified ${c.p}$timeout${c._}, timeout must be a positive integer');
  }

  // Check threads
  try {
    threads = int.parse(threads);
  } catch (e) {
    errorMessage('Invalid threads specified ${c.p}$threads${c._}, threads must be a positive integer');
  }

  // Check delay
  try {
    delay = int.parse(delay);
  } catch (e) {
    errorMessage('Invalid delay specified ${c.p}$delay${c._}, delay must be a positive integer');
  }

  // Check output
  if (output != null) {
    try {
      await File(output).writeAsString('');
    } catch (e) {
      errorMessage('Invalid file path specified ${c.p}$output${c._}\n    Full Trace: ${c.o}$e');
    }
  }

  // Check cookies
  if (cookies != null) {
    headers = {'User-Agent':user_agent,'Cookie': cookies};
  } else {
    headers = {'User-Agent':user_agent};
  }

  // Scan specific globals
  var start_time = DateTime.now();
  var webserver;
  try {
    webserver = (await http.get(url)).headers['server'];
  } catch (e) {
    errorMessage('Invalid url or host specified, ${c.p}$url${c._} is not up.',e: e);
  }
  
  print(c.g+'='*75);
  print('${c.b}Start Time.....: ${c.c}${start_time.hour}:${start_time.minute}:${start_time.second}');
  print('${c.b}URL To Scan....: ${c.c}$url/');
  print('${c.b}Webserver......: ${c.c}$webserver');
  print('${c.b}Wordlist Length: ${c.c}${word_list.length}');
  print('${c.b}Extensions.....: ${c.c}${extensions.length <= 8 ? extensions : extensions.length}');
  print('${c.b}User Agent.....: ${c.c}$user_agent ${user_agent == 'rotate' ? (user_agents.length) : ''}');
  print('${c.b}Cookies........: ${c.c}$cookies');
  print('${c.b}Threads........: ${c.c}$threads');
  print('${c.b}Timeout........: ${c.c}${timeout}s');
  print('${c.b}Delay..........: ${c.c}${delay}s');
  print(c.g+'='*75);
  print('${c.y}[*]${c.o}         Status Code Content Length Content-Type Header      URL${c._}');
  
  // THREADING
  var segments = segment(word_list, word_list.length~/threads);

  
  var total = word_list.length * extensions.length;
  var count = 0;
  var errors = 0;


  rc.listen((message) {
    final dt = DateTime.now();
    final time = '[${dt.hour}:${dt.minute}:${dt.second < 10 ? '0'+dt.second.toString() : dt.second}]'.padRight(12);
    if (message[0] == 0) {
      count++;
      stdout.write('${c.g}[${(count/total*100).toStringAsFixed(2)}%]${c._} ' + message[1]);
    } else if (message[0] == 1) {
      print('${c.g}$time${c._}' + message[1]);
      // print('${c.g}[$count/$total]${c._}  ' + message[1]);
    } else {
      errors++;
      if (verbosity != null) {
        print('${c.r}$time${c._}' + message[1] + ' '*50);
      }
    }
  });

  // ASYNC METHOD
  await Future.wait([
    for (var segment in segments)
      scanIsolateAsync(segment),
  ]);

  print(c.g+'='*75);
  print('${c.b}Duration.......: ${c.c}${DateTime.now().difference(start_time).inSeconds}s (started: ${start_time})');
  print('${c.b}Total Scans....: ${c.c}$count');
  print('${c.b}Total Errors...: ${c.c}$errors');
  print('${c.b}Total Found....: ${c.c}${count-errors}');
  print('${c.b}URL To Scan....: ${c.c}$url/');
  print('${c.b}Webserver......: ${c.c}$webserver');
  print('${c.b}Wordlist Length: ${c.c}${word_list.length}');
  print('${c.b}Extensions.....: ${c.c}${extensions.length <= 8 ? extensions : extensions.length}');
  print('${c.b}User Agent.....: ${c.c}$user_agent ${user_agent == 'rotate' ? (user_agents.length) : ''}');
  print('${c.b}Cookies........: ${c.c}$cookies');
  print(c.g+'='*75);
  exit(0);
}



Future<void> scanIsolateAsync(List wl) async {
  // Initial Declarations
  var r;

  // // start scan
  for (var word in wl) {
    for (var ext in extensions) {
      if (user_agent == 'rotate') {
        headers['User-Agent'] = user_agents[Random().nextInt(user_agents.length)];
      }
      rc.sendPort.send([0,'Trying ${c.b}${word+ext}${' '*(75-(word+ext).length)}\r']);
      try {
        r = await http.get('$url/$word$ext', headers: headers).timeout(Duration(seconds: timeout));
        if (show_404 != null || r.statusCode != 404) {
          rc.sendPort.send([1,'${r.statusCode.toString().padRight(11)} ${r.body.length.toString().padRight(14)} ${r.headers['content-type'].padRight(24)} ${word+ext}${' '*(40-(word+ext).length)}']);
          // Logging
          if (output != null) {
            await File(output).writeAsString('${r.statusCode} ${r.body.length} ${r.headers['content-type']} ${word+ext}\n', mode: FileMode.append);
          }
        }
      } catch (e) {
        rc.sendPort.send([2,e.toString()]);
      }
      if (delay > 0) {
        await Future.delayed(Duration(seconds: delay));
      }
    }
  }
}