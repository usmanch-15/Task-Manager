import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';

class ExportService {
  static Future<void> exportAsCSV(List<Task> tasks) async {
    List<List<dynamic>> rows = [];

    // Add headers
    rows.add([
      'ID',
      'Title',
      'Description',
      'Due Date',
      'Category',
      'Priority',
      'Status',
      'Progress',
    ]);

    // Add data
    for (var task in tasks) {
      rows.add([
        task.id,
        task.title,
        task.description,
        task.dueDate.toIso8601String(),
        task.category,
        task.priority,
        task.isCompleted ? 'Completed' : 'Pending',
        '${task.progress}%',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tasks_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);

    await Share.shareFiles([file.path], text: 'Tasks Export');
  }

  static Future<void> exportAsPDF(List<Task> tasks) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'Task Manager Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        },
        build: (context) => [
          pw.Text(
            'Generated on: ${dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Title', 'Due Date', 'Category', 'Priority', 'Status'],
            data: tasks.map((task) {
              return [
                task.title,
                dateFormat.format(task.dueDate),
                task.category,
                task.priority == 1
                    ? 'Low'
                    : task.priority == 2
                    ? 'Medium'
                    : 'High',
                task.isCompleted ? 'Completed' : 'Pending',
              ];
            }).toList(),
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Summary:',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Total Tasks: ${tasks.length}'),
          pw.Text(
              'Completed: ${tasks.where((t) => t.isCompleted).length}'),
          pw.Text('Pending: ${tasks.where((t) => !t.isCompleted).length}'),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static Future<void> shareViaEmail(List<Task> tasks) async {
    final dateFormat = DateFormat('MMM d, yyyy hh:mm a');

    String body = 'My Tasks\n\n';
    for (var task in tasks) {
      body += '''
Title: ${task.title}
Due: ${dateFormat.format(task.dueDate)}
Status: ${task.isCompleted ? '✅' : '⏳'}
Priority: ${task.priority == 1 ? '🔵' : task.priority == 2 ? '🟡' : '🔴'}
Category: ${task.category}
${'-' * 30}\n
''';
    }

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: '',
      query: encodeQueryParameters(<String, String>{
        'subject': 'My Tasks List',
        'body': body,
      }),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  static String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}