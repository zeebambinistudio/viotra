// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

void main() async {
  // CONFIG
  final csvFile = File('donatur.csv');
  final jsonFile = File('donatur.json');

  // COLORS
  const reset = '\x1B[0m';
  const red = '\x1B[31m';
  const green = '\x1B[32m';
  const yellow = '\x1B[33m';

  // csv lookup
  print('${yellow}Checking CSV...$reset');
  if (!csvFile.existsSync()) {
    print('${red}FAILED: donatur.csv not found!$reset');
    exit(1);
  }

  // convert csv to json
  print('${yellow}Converting CSV to JSON...$reset');
  try {
    final lines = await csvFile.readAsLines();

    if (lines.length < 2) {
      print('${red}FAILED: CSV is empty or just header!$reset');
      exit(1);
    }

    final List<Map<String, dynamic>> jsonData = [];

    // start from index 1 to bypass header (0)
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // split by semicolon
      final values = line.split(';');

      if (values.length >= 4) {
        jsonData.add({
          'name': values[0].trim(),
          'date': values[1].trim(),
          'msg': values[2].trim(),
          'amnt': double.tryParse(values[3].trim())?.toInt() ?? 0,
        });
      }
    }

    // format json string (indentation)
    final jsonString = JsonEncoder.withIndent(' ').convert(jsonData);
    await jsonFile.writeAsString(jsonString);
    print('${green}JSON successfully generated!$reset');
  } catch (e) {
    print('${red}FAILED: $e$reset');
    exit(1);
  }

  // TIME TO GIT
  print('\n${yellow}Synchronizing Git...$reset');

  final String repoRoot = '..';
  Future<void> runGit(List<String> args) async {
    final result = await Process.run('git', args, workingDirectory: repoRoot);
    if (result.exitCode != 0) {
      print('${red}FAILED: git ${args.join(' ')}$reset');
      print('$red${result.stderr}$reset');
      exit(1);
    } else {
      print('${green}git ${args.join(' ')} -> OK$reset');
    }
  }

  // pull first
  await runGit(['pull']);

  // add everything
  await runGit(['add', '.']);

  // commit
  final timestamp = DateTime.now().toString().split('.')[0];
  final commitMessage = 'Auto-update donations data: $timestamp';

  await runGit(['commit', '-m', commitMessage]);

  // push
  await runGit(['push']);

  print('\n${green}SUCCESS: Update Complete!$reset');
  print('${green}New donatur.json currently airing!$reset');
}
