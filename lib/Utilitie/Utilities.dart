import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:med_scheduler_front/Models/ConnectionError.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Utilities {
  final BuildContext context;
  bool connectionErrorHandled = false;

  Utilities({required this.context});

  String extractLastNumber(String input) {
    RegExp regExp = RegExp(r'\d+$');
    Match? match = regExp.firstMatch(input);

    if (match != null) {
      String val = match.group(0)!;
      return val;
    } else {
      // Aucun nombre trouvé dans la chaîne
      throw const FormatException("Aucun nombre trouvé dans la chaîne.");
    }
  }

  void error(String description) {
    AwesomeDialog(
      context: context,
      dialogBackgroundColor: Colors.redAccent,
      dialogType: DialogType.info,
      btnCancelColor: Colors.grey,
      animType: AnimType.rightSlide,
      titleTextStyle: const TextStyle(letterSpacing: 2, color: Colors.white),
      descTextStyle: TextStyle(
          letterSpacing: 2, color: Colors.white.withOpacity(0.8), fontSize: 16),
      title: '$description',
      desc: '$description',
      btnCancelOnPress: () {},
      btnOkOnPress: () {},
    ).show();
  }

  void UpdateCenter() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Centre modifié',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void UpdateUtilisateur() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Médecin modifié',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void UpdateSpecialite() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Specialité modifiée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void CreationCentre() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Centre crée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void CreationSpecialite() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Specialité crée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void DeleteCenter() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Centre supprimé',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void DeleteSpecialite() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Specialité supprimée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void CreationUtilisateur() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,

      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Medecin crée',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void DeleteMedecin() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Medecin supprimé',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void PasswordIsNotTheSame() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Erreur!',
        message:
            'Les champs du mot de passe et de confirmation ne correspondent pas.',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void ErrorConnexion() {
    AwesomeDialog(
      context: context,
      dialogBackgroundColor: Colors.redAccent,
      dialogType: DialogType.info,
      btnCancelColor: Colors.grey,
      animType: AnimType.rightSlide,
      titleTextStyle: const TextStyle(letterSpacing: 2, color: Colors.white),
      descTextStyle: TextStyle(
          letterSpacing: 2, color: Colors.white.withOpacity(0.8), fontSize: 16),
      title: 'Erreur de connexion',
      desc:
          'Il y a peut-etre une erreur de connexion.\n\n Verifier votre connexion',
      btnCancelOnPress: () {},
      btnOkOnPress: () {},
    ).show();
  }

  void RdvValider() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Rendez-vous enregistré',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void modifPasswordValider() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Mot de passe modifié',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void ModificationUtilisateur() {
    final materialBanner = MaterialBanner(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      backgroundColor: Colors.transparent,
      forceActionsBelow: true,
      content: AwesomeSnackbarContent(
        title: 'Succès!!',
        message: 'Modification succès',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.success,
        // to configure for material banner
        inMaterialBanner: true,
      ),
      actions: const [SizedBox.shrink()],
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(materialBanner);
  }

  void ModificationError(String errorDesc) {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Erreur!',
        message: '$errorDesc',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void loginFailed() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      margin: const EdgeInsets.all(20),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Introuvable!',
        message: 'Utilisateur introuvable.',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void emailInvalide() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Invalide!',
        message: 'E-mail invalide.',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void ChampsIncomplets() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Erreur!',
        message: 'Champs incomplets!',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.failure,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String extractApiPath(String fullPath) {
    const String apiPrefix = '/med_scheduler_api/public';
    if (fullPath.startsWith(apiPrefix)) {
      return fullPath.substring(apiPrefix.length);
    } else {
      // La chaîne ne commence pas par le préfixe attendu
      return fullPath;
    }
  }

  String extraireNomFichier(String url) {
    // Extraire le nom du fichier de l'URL
    return url.substring(url.lastIndexOf('/') + 1);
  }

  String ajouterPrefixe(String chemin) {
    // Vérifier si le préfixe est déjà présent
    if (!chemin.startsWith('/images/profiles/')) {
      // Ajouter le préfixe s'il n'est pas déjà inclus
      chemin = '/images/profiles/' + chemin;
    }
    return chemin;
  }

  void handleConnectionError(error) {
    if (!connectionErrorHandled) {
      if (error is ConnectionError) {
        ErrorConnexion();
      } else {
        print("Une erreur s'est produite\n Verifier votre connexion internet!");
      }
      connectionErrorHandled = true;
    }
  }

  Future<bool> isConnectionAvailable() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void appointmentAlreadyExist() {
    SnackBar snackBar = SnackBar(
      /// need to set following properties for best effect of awesome_snackbar_content
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        color: Colors.redAccent,
        title: 'Invalide!',
        message: 'Cette plage horaire est déjà réservée.',

        /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
        contentType: ContentType.warning,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  String formatPhoneNumber(String phoneNumber) {
    // Supprimer les espaces inutiles
    phoneNumber = phoneNumber.replaceAll(' ', '');

    // Vérifier si le numéro de téléphone commence par "+261"
    if (phoneNumber.startsWith('+261')) {
      // Supprimer le préfixe "+261"
      phoneNumber = phoneNumber.substring(4);
      // Ajouter les espaces après chaque groupe de chiffres
      return phoneNumber.substring(0, 2) +
          ' ' +
          phoneNumber.substring(2, 4) +
          ' ' +
          phoneNumber.substring(4, 7) +
          ' ' +
          phoneNumber.substring(7);
    }

    // Retourner le numéro de téléphone non modifié s'il ne commence pas par "+261"
    return phoneNumber;
  }

  void errorDoctorEmptyCenterOrSpeciality(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG);
  }

   void copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('numero copié dans le presse-papiers'),
    ));
  }



  bool isToday(DateTime startAt, DateTime timeStart) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day - now.weekday);
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    bool isIt = false;
    bool val = DateFormat('yyyy-MM-dd').format(startAt) ==
        DateFormat('yyyy-MM-dd').format(now);
    if (val) {
      if (now.hour < timeStart.hour) {
        isIt = false;
      } else {
        isIt = true;
      }
    }

    return isIt;
  }



  String formatTimeAppointmentNotif(
      DateTime startDateTime, DateTime timeStart, DateTime timeEnd) {
    // Liste des jours de la semaine
    final List<String> jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];

    // Liste des mois de l'année
    final List<String> mois = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];

    // Extraire les composants de la date et de l'heure
    int jour = startDateTime.day;
    int moisIndex = startDateTime.month;
    int annee = startDateTime.year;
    int heureStart = timeStart.hour;
    int minuteStart = timeStart.minute;
    int heureEnd = timeEnd.hour;
    int minuteEnd = timeEnd.minute;

    // Formater le jour de la semaine
    String jourSemaine = jours[startDateTime.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Formater l'heure
    String formatHeureStart =
        '${heureStart.toString().padLeft(2, '0')}:${minuteStart.toString().padLeft(2, '0')}';
    String formatHeureEnd =
        '${heureEnd.toString().padLeft(2, '0')}:${minuteEnd.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat = 'Ajourd\'hui de $formatHeureStart - $formatHeureEnd';

    return resultat;
  }


}
