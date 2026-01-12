import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:jprojets/models/projet.dart';
import 'package:jprojets/models/information.dart';
import 'package:jprojets/models/tache.dart';

/// Service pour générer et partager des PDF pour les projets et informations
class PdfExportService {
  // Cache pour les images chargées
  final Map<String, Uint8List> _imageCache = {};
  
  // ==================== STYLES PDF ====================
  final pw.TextStyle _subtitleStyle = pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.grey800,
  );
  
  final pw.TextStyle _headerStyle = pw.TextStyle(
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  
  final pw.TextStyle _bodyStyle = pw.TextStyle(
    fontSize: 11,
    color: PdfColors.grey800,
  );
  
  final pw.TextStyle _smallStyle = pw.TextStyle(
    fontSize: 10,
    color: PdfColors.grey600,
  );
  
  // ==================== EXPORT PROJET ====================
  
  /// Génère un PDF pour un projet
  Future<Uint8List> generateProjetPdf(Projet projet) async {
    final pdf = pw.Document();
    
    // Charger le logo asynchrone
    final logoBytes = await _getLogoImage();
    
    // Page de couverture
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildProjetCoverPage(projet, logoBytes);
        },
      ),
    );
    
    // Page des détails
    if (projet.description != null && projet.description!.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildProjetDescriptionPage(projet);
          },
        ),
      );
    }
    
    // Pages des tâches (MultiPage pour gérer plusieurs pages)
    if (projet.taches.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(30),
          header: (pw.Context context) {
            return _buildTachesHeader(projet);
          },
          build: (pw.Context context) {
            return _buildTachesContent(projet);
          },
          footer: (pw.Context context) {
            return _buildPageFooter(context);
          },
        ),
      );
    }
    
    // Pages des tâches détaillées (sous-tâches et checklists)
    for (var tache in projet.taches) {
      if (tache.sousTaches != null && tache.sousTaches!.isNotEmpty || 
          tache.checklist != null && tache.checklist!.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(30),
            header: (pw.Context context) {
              return _buildTacheDetailHeader(tache, context.pageNumber, context.pagesCount);
            },
            build: (pw.Context context) {
              return _buildTacheDetailContent(tache);
            },
            footer: (pw.Context context) {
              return _buildPageFooter(context);
            },
          ),
        );
      }
    }
    
    // Page avec la liste des images (MultiPage pour la liste)
    if (projet.images != null && projet.images!.isNotEmpty) {
      
      // Pages séparées pour chaque image (Page simple, pas MultiPage)
      for (int i = 0; i < projet.images!.length; i++) {
        final imagePath = projet.images![i];
        try {
          final imageBytes = await _getImageBytes(imagePath);
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.all(30),
              build: (pw.Context context) {
                return pw.Column(
                  children: [
                    pw.Text(
                      'Image ${i + 1}/${projet.images!.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      path.basename(imagePath),
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Image(
                        pw.MemoryImage(imageBytes),
                        fit: pw.BoxFit.contain,
                        height: 400,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        } catch (e) {
          print('❌ Erreur chargement image $imagePath: $e');
          // Page d'erreur
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.all(30),
              build: (pw.Context context) {
                return pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Image ${i + 1}/${projet.images!.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Erreur de chargement',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.red),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      path.basename(imagePath),
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      height: 200,
                      width: 300,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'Image non disponible',
                          style: pw.TextStyle(color: PdfColors.grey600),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }
    }

    return await pdf.save();
  }
  
  // ==================== EXPORT INFORMATION ====================
  
  /// Génère un PDF pour une information
  Future<Uint8List> generateInformationPdf(Information info) async {
    final pdf = pw.Document();
    
    // Charger le logo asynchrone
    final logoBytes = await _getLogoImage();
    
    // Page de couverture
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildInformationCoverPage(info, logoBytes);
        },
      ),
    );
    
    // Pages des points principaux (MultiPage)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(30),
        header: (pw.Context context) {
          return _buildPointsHeader(info, context.pageNumber, context.pagesCount);
        },
        build: (pw.Context context) {
          return _buildPointsContent(info);
        },
        footer: (pw.Context context) {
          return _buildPageFooter(context);
        },
      ),
    );
    
    // Page avec la liste des images (MultiPage pour la liste)
    if (info.images != null && info.images!.isNotEmpty) {
      
      // Pages séparées pour chaque image (Page simple, pas MultiPage)
      for (int i = 0; i < info.images!.length; i++) {
        final imagePath = info.images![i];
        try {
          final imageBytes = await _getImageBytes(imagePath);
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.all(30),
              build: (pw.Context context) {
                return pw.Column(
                  children: [
                    pw.Text(
                      'Image ${i + 1}/${info.images!.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      path.basename(imagePath),
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Image(
                        pw.MemoryImage(imageBytes),
                        fit: pw.BoxFit.contain,
                        height: 400,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        } catch (e) {
          print('❌ Erreur chargement image $imagePath: $e');
          // Page d'erreur
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.all(30),
              build: (pw.Context context) {
                return pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Image ${i + 1}/${info.images!.length}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'Erreur de chargement',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.red),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      path.basename(imagePath),
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }
    }
    
    return await pdf.save();
  }
  
  // ==================== MÉTHODES PRIVÉES PROJET ====================
  
  pw.Widget _buildProjetCoverPage(Projet projet, Uint8List logoBytes) {
    final dateStr = '${projet.dateCreation.day}/${projet.dateCreation.month}/${projet.dateCreation.year}';
    final tachesCompletees = projet.taches.where((t) => t.estCompletee).length;
    final progress = projet.taches.isEmpty ? 0.0 : tachesCompletees / projet.taches.length * 100;
    
    final children = <pw.Widget>[
      // Logo
      pw.Container(
        width: 80,
        height: 80,
        child: pw.Image(
          pw.MemoryImage(logoBytes),
          fit: pw.BoxFit.contain,
        ),
      ),
      
      pw.SizedBox(height: 40),
      
      // Titre
      pw.Text(
        projet.titre,
        style: pw.TextStyle(
          fontSize: 28,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
      
      pw.SizedBox(height: 40),
      
      // Statut
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(
              color: _getStatusColorPdf(projet.statut),
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            _getStatusText(projet.statut).toUpperCase(),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _getStatusColorPdf(projet.statut),
            ),
          ),
        ],
      ),
      
      pw.SizedBox(height: 50),
      
      // Informations clés
      pw.Container(
        width: double.infinity,
        padding: pw.EdgeInsets.all(25),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
          borderRadius: pw.BorderRadius.circular(15),
        ),
        child: pw.Column(
          children: [
            // Date
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date de création :', style: _subtitleStyle),
                pw.Text(dateStr, style: _bodyStyle),
              ],
            ),
            
            pw.Divider(color: PdfColors.grey300, height: 15),
            
            // Tâches
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Nombre de tâches :', style: _subtitleStyle),
                pw.Text('${projet.taches.length}', style: _bodyStyle),
              ],
            ),
            
            pw.Divider(color: PdfColors.grey300, height: 15),
            
            // Progression
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Progression :', style: _subtitleStyle),
                pw.Text('${progress.toStringAsFixed(1)}%', style: _bodyStyle),
              ],
            ),
            
            pw.Divider(color: PdfColors.grey300, height: 15),
            
            // Images
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Images associées :', style: _subtitleStyle),
                pw.Text(
                  projet.images != null ? '${projet.images!.length}' : '0',
                  style: _bodyStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    ];
    
    // Footer
    children.addAll([
      pw.SizedBox(height: 40),
      pw.Text(
        'Document généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} '
        'par l\'application JProjets',
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.center,
      ),
    ]);
    
    return pw.Container(
      padding: pw.EdgeInsets.all(50),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
  
  pw.Widget _buildProjetDescriptionPage(Projet projet) {
    return pw.Container(
      padding: pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Description',
            style: _headerStyle.copyWith(fontSize: 24),
          ),
          
          pw.SizedBox(height: 25),
          
          if (projet.description != null && projet.description!.isNotEmpty)
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                projet.description!,
                style: _bodyStyle.copyWith(fontSize: 12),
                textAlign: pw.TextAlign.justify,
              ),
            ),
          
          pw.SizedBox(height: 40),
        ],
      ),
    );
  }
  
  // En-tête pour les pages de tâches
  pw.Widget _buildTachesHeader(Projet projet) {
    final tachesCompletees = projet.taches.where((t) => t.estCompletee).length;
    final progress = projet.taches.isEmpty ? 0.0 : tachesCompletees / projet.taches.length * 100;
    
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Tâches du projet',
              style: _headerStyle.copyWith(fontSize: 18),
            ),
            pw.Text(
              '${tachesCompletees}/${projet.taches.length} complétées',
              style: _smallStyle.copyWith(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        
        pw.SizedBox(height: 10),
        
        // Barre de progression
        pw.Container(
          height: 8,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Stack(
            children: [
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: _getStatusColorPdf(projet.statut),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.SizedBox(
                  width: (progress / 100) * 500, // Largeur relative
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 5),
        
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Progression globale',
              style: _smallStyle,
            ),
            pw.Text(
              '${progress.toStringAsFixed(1)}%',
              style: _smallStyle.copyWith(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        
        pw.SizedBox(height: 20),
      ],
    );
  }
  
  // Contenu pour les pages de tâches (MultiPage)
  List<pw.Widget> _buildTachesContent(Projet projet) {
    final widgets = <pw.Widget>[];
    
    for (var i = 0; i < projet.taches.length; i++) {
      final tache = projet.taches[i];
      final numero = i + 1;
      
      widgets.add(
        _buildTacheItem(tache, numero)
      );
      
      // Ajouter un espace entre les tâches (sauf pour la dernière)
      if (i < projet.taches.length - 1) {
        widgets.add(pw.SizedBox(height: 12));
      }
    }
    
    return widgets;
  }
  
  pw.Widget _buildTacheItem(Tache tache, int numero) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Padding(
        padding: pw.EdgeInsets.all(12),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Checkbox et numéro
            pw.Column(
              children: [
                pw.Container(
                  width: 16,
                  height: 16,
                  margin: pw.EdgeInsets.only(bottom: 5),
                  decoration: pw.BoxDecoration(
                    color: tache.estCompletee 
                        ? PdfColors.grey800 
                        : PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(
                      color: PdfColors.grey600,
                      width: 1,
                    ),
                  ),
                  child: tache.estCompletee
                      ? pw.Center(
                          child: pw.Text(
                            '✓',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                pw.Text(
                  '$numero',
                  style: _smallStyle,
                ),
              ],
            ),
            
            pw.SizedBox(width: 15),
            
            // Détails tâche
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tache.titre,
                    style: _bodyStyle.copyWith(
                      fontWeight: tache.estCompletee
                          ? pw.FontWeight.normal
                          : pw.FontWeight.bold,
                      color: tache.estCompletee
                          ? PdfColors.grey600
                          : PdfColors.black,
                    ),
                  ),
                  
                  if (tache.description != null && 
                      tache.description!.isNotEmpty)
                    pw.Container(
                      margin: pw.EdgeInsets.only(top: 5),
                      child: pw.Text(
                        tache.description!,
                        style: _smallStyle,
                      ),
                    ),
                  
                  // Informations supplémentaires
                  pw.Container(
                    margin: pw.EdgeInsets.only(top: 8),
                    child: pw.Row(
                      children: [
                        // Sous-tâches
                        if (tache.sousTaches != null && 
                            tache.sousTaches!.isNotEmpty)
                          pw.Container(
                            margin: pw.EdgeInsets.only(right: 10),
                            padding: pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey100,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              '${tache.sousTaches!.length} sous-tâche(s)',
                              style: _smallStyle.copyWith(
                                color: PdfColors.grey600,
                              ),
                            ),
                          ),
                        
                        // Checklist
                        if (tache.checklist != null && 
                            tache.checklist!.isNotEmpty)
                          pw.Container(
                            padding: pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey100,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              '${tache.checklist!.length} item(s) checklist',
                              style: _smallStyle.copyWith(
                                color: PdfColors.grey600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // En-tête pour les pages de détails de tâches
  pw.Widget _buildTacheDetailHeader(Tache tache, int pageNumber, int totalPages) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Détails de la tâche',
              style: _headerStyle.copyWith(fontSize: 18),
            ),
            if (totalPages > 1)
              pw.Text(
                'Page $pageNumber/$totalPages',
                style: _smallStyle,
              ),
          ],
        ),
        
        pw.SizedBox(height: 5),
        
        pw.Text(
          tache.titre,
          style: _subtitleStyle.copyWith(fontSize: 16),
        ),
        
        pw.SizedBox(height: 20),
      ],
    );
  }
  
  // Contenu pour les pages de détails de tâches (MultiPage)
  List<pw.Widget> _buildTacheDetailContent(Tache tache) {
    final widgets = <pw.Widget>[];
    
    // Description
    if (tache.description != null && tache.description!.isNotEmpty) {
      widgets.add(
        pw.Container(
          margin: pw.EdgeInsets.only(bottom: 20),
          padding: pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Description',
                style: _subtitleStyle.copyWith(fontSize: 12),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                tache.description!,
                style: _bodyStyle,
                textAlign: pw.TextAlign.justify,
              ),
            ],
          ),
        ),
      );
    }
    
    // Sous-tâches
    if (tache.sousTaches != null && tache.sousTaches!.isNotEmpty) {
      widgets.add(
        pw.Container(
          margin: pw.EdgeInsets.only(bottom: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Sous-tâches (${tache.sousTaches!.length})',
                style: _subtitleStyle,
              ),
              
              pw.SizedBox(height: 10),
              
              for (var i = 0; i < tache.sousTaches!.length; i++)
                pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Padding(
                    padding: pw.EdgeInsets.all(10),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        pw.Container(
                          width: 14,
                          height: 14,
                          margin: pw.EdgeInsets.only(top: 2),
                          decoration: pw.BoxDecoration(
                            color: tache.sousTaches![i].estCompletee 
                                ? PdfColors.grey800 
                                : PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(3),
                            border: pw.Border.all(
                              color: PdfColors.grey600,
                              width: 1,
                            ),
                          ),
                          child: tache.sousTaches![i].estCompletee
                              ? pw.Center(
                                  child: pw.Text(
                                    '✓',
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        
                        pw.SizedBox(width: 12),
                        
                        // Contenu
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                '${i + 1}. ${tache.sousTaches![i].titre}',
                                style: _bodyStyle.copyWith(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: tache.sousTaches![i].estCompletee
                                      ? PdfColors.grey600
                                      : PdfColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Checklist
    if (tache.checklist != null && tache.checklist!.isNotEmpty) {
      widgets.add(
        pw.Container(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Checklist (${tache.checklist!.length} items)',
                style: _subtitleStyle,
              ),
              
              pw.SizedBox(height: 10),
              
              for (var i = 0; i < tache.checklist!.length; i++)
                pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 14,
                        height: 14,
                        margin: pw.EdgeInsets.only(top: 1),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey500,
                            width: 1,
                          ),
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                      
                      pw.SizedBox(width: 10),
                      
                      pw.Expanded(
                        child: pw.Text(
                          '${i + 1}. ${tache.checklist![i]}',
                          style: _bodyStyle.copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }
  
  // ==================== MÉTHODES PRIVÉES INFORMATION ====================
  
  pw.Widget _buildInformationCoverPage(Information info, Uint8List logoBytes) {
    final dateStr = '${info.dateCreation.day}/${info.dateCreation.month}/${info.dateCreation.year}';
    
    return pw.Container(
      padding: pw.EdgeInsets.all(50),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo
          pw.Container(
            width: 80,
            height: 80,
            child: pw.Image(
              pw.MemoryImage(logoBytes),
              fit: pw.BoxFit.contain,
            ),
          ),
          
          pw.SizedBox(height: 40),
          
          // Titre
          pw.Text(
            info.titre,
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
          
          pw.SizedBox(height: 50),
          
          // Points clés
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              borderRadius: pw.BorderRadius.circular(15),
            ),
            child: pw.Column(
              children: [
                // Nombre de points
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Nombre de points :', style: _subtitleStyle),
                    pw.Text('${info.points.length}', style: _bodyStyle),
                  ],
                ),
                
                pw.Divider(color: PdfColors.grey300, height: 15),
                
                // Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date d\'enregistrement :', style: _subtitleStyle),
                    pw.Text(dateStr, style: _bodyStyle),
                  ],
                ),
                
                pw.Divider(color: PdfColors.grey300, height: 15),
                
                // Images
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Images associées :', style: _subtitleStyle),
                    pw.Text(
                      info.images != null ? '${info.images!.length}' : '0',
                      style: _bodyStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 40),
          
          // Citation
          pw.Container(
            padding: pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              'La connaissance est le seul bien qui augmente quand on le partage.',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.black,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          
          pw.SizedBox(height: 40),
          
          // Footer
          pw.Text(
            'Document généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} '
            'par l\'application JProjets',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // En-tête pour les pages de points
  pw.Widget _buildPointsHeader(Information info, int pageNumber, int totalPages) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Points clés',
              style: _headerStyle.copyWith(fontSize: 18),
            ),
            if (totalPages > 1)
              pw.Text(
                'Page $pageNumber/$totalPages',
                style: _smallStyle,
              ),
          ],
        ),
        
        pw.SizedBox(height: 5),
        
        pw.Text(
          '${info.points.length} point${info.points.length > 1 ? 's' : ''} documenté${info.points.length > 1 ? 's' : ''}',
          style: _smallStyle,
        ),
        
        pw.SizedBox(height: 20),
      ],
    );
  }
  
  // Contenu pour les pages de points (MultiPage)
  List<pw.Widget> _buildPointsContent(Information info) {
    final widgets = <pw.Widget>[];
    
    for (var i = 0; i < info.points.length; i++) {
      final point = info.points[i];
      final numero = i + 1;
      
      widgets.add(
        pw.Container(
          margin: pw.EdgeInsets.only(bottom: 15),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Numéro
              pw.Container(
                width: 22,
                height: 22,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                  borderRadius: pw.BorderRadius.circular(11),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '$numero',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.black,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              pw.SizedBox(width: 12),
              
              // Contenu
              pw.Expanded(
                child: pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Text(
                    point,
                    style: _bodyStyle.copyWith(
                      color: PdfColors.grey800,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      
      // Ajouter un espace entre les points (sauf pour le dernier)
      if (i < info.points.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }
    
    return widgets;
  }
  
  // ==================== MÉTHODES POUR IMAGES (MULTIPAGE) ====================
  
  // En-tête pour les pages d'images
  pw.Widget _buildImagesHeader(String title, int totalImages, int pageNumber, int totalPages) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: _headerStyle.copyWith(fontSize: 18),
            ),
            if (totalPages > 1)
              pw.Text(
                'Page $pageNumber/$totalPages',
                style: _smallStyle,
              ),
          ],
        ),
        
        pw.SizedBox(height: 5),
        
        pw.Text(
          '$totalImages image${totalImages > 1 ? 's' : ''}',
          style: _smallStyle,
        ),
        
        pw.SizedBox(height: 20),
      ],
    );
  }
  
  // Contenu pour les pages d'images (MultiPage) - LISTE DES IMAGES
  List<pw.Widget> _buildImagesListContent(List<String> imagePaths) {
    final widgets = <pw.Widget>[];
    
    widgets.add(
      pw.Text(
        'Liste des images (${imagePaths.length}):',
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
    
    widgets.add(pw.SizedBox(height: 20));
    
    for (var i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      final imageNumber = i + 1;
      
      widgets.add(
        pw.Container(
          margin: pw.EdgeInsets.only(bottom: 15),
          padding: pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.grey50,
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 30,
                height: 30,
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '$imageNumber',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              pw.SizedBox(width: 15),
              
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Image $imageNumber',
                      style: _smallStyle.copyWith(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      path.basename(imagePath),
                      style: _smallStyle.copyWith(
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }
  
  // ==================== FOOTER POUR TOUTES LES PAGES ====================
  
  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Page ${context.pageNumber} sur ${context.pagesCount}',
        style: _smallStyle.copyWith(
          color: PdfColors.grey500,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }
  
  // ==================== MÉTHODES UTILITAIRES ====================
  
  PdfColor _getStatusColorPdf(String statut) {
    switch (statut) {
      case 'en_attente':
        return PdfColors.orange;
      case 'en_cours':
        return PdfColors.blue;
      case 'termine':
        return PdfColors.green;
      default:
        return PdfColors.grey;
    }
  }
  
  String _getStatusText(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'en_cours': return 'En cours';
      case 'termine': return 'Terminé';
      default: return 'Inconnu';
    }
  }
  
  // ==================== GESTION DES IMAGES ====================
  
  Future<Uint8List> _getLogoImage() async {
    const logoKey = 'logo_asset';
    
    // Retourner depuis le cache si disponible
    if (_imageCache.containsKey(logoKey)) {
      return _imageCache[logoKey]!;
    }
    
    try {
      // Charger le logo depuis les assets
      final ByteData byteData = await rootBundle.load('assets/logo.png');
      final Uint8List imageBytes = byteData.buffer.asUint8List();
      
      // Mettre en cache
      _imageCache[logoKey] = imageBytes;
      
      return imageBytes;
    } catch (e) {
      print('Erreur de chargement du logo: $e');
      
      // Retourner un logo par défaut si le fichier n'existe pas
      return _createDefaultLogo();
    }
  }

  Future<Uint8List> _getImageBytes(String imagePath) async {
    // Retourner depuis le cache si disponible
    if (_imageCache.containsKey(imagePath)) {
      return _imageCache[imagePath]!;
    }
    
    try {
      print('🔍 Tentative de chargement de l\'image: $imagePath');
      
      // Vérifier si c'est un chemin de fichier
      final File imageFile = File(imagePath);
      
      if (await imageFile.exists()) {
        print('✅ Fichier image existe');
        
        // Charger depuis le système de fichiers
        final Uint8List imageBytes = await imageFile.readAsBytes();
        print('✅ Image chargée avec succès: ${imageBytes.length} bytes');
        
        // Mettre en cache
        _imageCache[imagePath] = imageBytes;
        
        return imageBytes;
      } else {
        print('❌ Fichier image n\'existe pas: $imagePath');
        
        // Si le fichier n'existe pas, retourner un placeholder
        return _createImagePlaceholder('Image non disponible: ${path.basename(imagePath)}');
      }
    } catch (e, stackTrace) {
      print('❌ Erreur de chargement de l\'image $imagePath: $e');
      print('Stack trace: $stackTrace');
      
      return _createImagePlaceholder('Erreur de chargement: ${path.basename(imagePath)}');
    }
  }

  Uint8List _createDefaultLogo() {
    final svgString = '''
      <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
        <rect width="100" height="100" rx="15" fill="#f8f9fa"/>
        <circle cx="50" cy="40" r="18" fill="#343a40"/>
        <text x="50" y="80" text-anchor="middle" font-family="Arial" font-size="12" fill="#495057">JProjets</text>
        <text x="50" y="95" text-anchor="middle" font-family="Arial" font-size="8" fill="#6c757d">LOGO</text>
      </svg>
    ''';
    return Uint8List.fromList(svgString.codeUnits);
  }

  Uint8List _createImagePlaceholder(String text) {
    final svgString = '''
      <svg width="400" height="250" xmlns="http://www.w3.org/2000/svg">
        <rect width="400" height="250" fill="#f8f9fa"/>
        <rect x="20" y="20" width="360" height="210" fill="#e9ecef" stroke="#dee2e6" stroke-width="1" rx="5"/>
        <text x="200" y="120" text-anchor="middle" font-family="Arial" font-size="14" fill="#495057">$text</text>
        <text x="200" y="140" text-anchor="middle" font-family="Arial" font-size="10" fill="#6c757d">(Image non disponible)</text>
        <path d="M180,160 L220,160 M200,140 L200,180" stroke="#adb5bd" stroke-width="2" stroke-linecap="round"/>
      </svg>
    ''';
    return Uint8List.fromList(svgString.codeUnits);
  }
  
  // ==================== PARTAGE ET ENREGISTREMENT ====================
  
  /// Enregistre le PDF localement et retourne le chemin
  Future<String> savePdfLocally(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      return filePath;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du PDF: $e');
    }
  }
  
  /// Partage le PDF via WhatsApp et autres applications
  Future<void> sharePdf(String filePath, String subject) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Le fichier PDF n\'existe pas');
      }
      
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
        text: 'Voici le PDF généré par JProjets: $subject',
      );
    } catch (e) {
      throw Exception('Erreur lors du partage: $e');
    }
  }
  
  /// Affiche une prévisualisation du PDF
  Future<void> previewPdf(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdfBytes,
      name: title,
    );
  }
  
  // Ajout de la couleur primaire manquante
  static final PdfColor primaryColor = PdfColor.fromInt(0xFF3498DB);
}