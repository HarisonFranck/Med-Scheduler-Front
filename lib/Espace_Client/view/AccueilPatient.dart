import 'package:flutter/material.dart';
import 'package:med_scheduler_front/Models/Medecin.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:math';
import 'package:icons_plus/icons_plus.dart';
import 'PriseDeRendezVous.dart';
import 'package:med_scheduler_front/Models/Utilisateur.dart';
import 'package:med_scheduler_front/Models/AuthProvider.dart';
import 'package:provider/provider.dart';
import 'package:med_scheduler_front/Models/Specialite.dart';
import 'dart:io';
import 'package:med_scheduler_front/Models/CustomAppointment.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:med_scheduler_front/Models/Centre.dart';
import 'AppointmentDetails.dart';
import 'package:intl/intl.dart';
import 'package:med_scheduler_front/Models/UrlBase.dart';
import 'package:med_scheduler_front/Models/Patient.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:device_calendar/device_calendar.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:med_scheduler_front/Repository/UserRepository.dart';
import 'package:med_scheduler_front/Repository/BaseRepository.dart';
import 'package:med_scheduler_front/Utilitie/Utilities.dart';
import 'package:med_scheduler_front/Models/AuthProviderUser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:med_scheduler_front/Models/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:med_scheduler_front/Models/FirebaseApi.dart';


class AccueilPatient extends StatefulWidget {
  @override
  _AccueilPatientState createState() => _AccueilPatientState();
}

class _AccueilPatientState extends State<AccueilPatient> {
  Patient? patient;

  UserRepository? userRepository;
  BaseRepository? baseRepository;
  Utilities? utilities;

  String FireBaseTokenPatient = "";


  Utilisateur? user;

  late Future<List<Medecin>> medecinsFuture;
  late Future<List<Specialite>> specialitesFuture;

  TextEditingController searchLastName = TextEditingController();
  TextEditingController searchCenter = TextEditingController();
  TextEditingController searchSpecialite = TextEditingController();
  TextEditingController searchLocation = TextEditingController();

  late AuthProvider authProvider;
  late String token;
  late int idUser = 0;
  bool dataLoaded = false;
  String baseUrl = UrlBase().baseUrl;

  int currentPage = 1;

  bool isLoading = false;

  ScrollController scrollController = ScrollController();

  Future<List<Medecin>> loadMoreData() async {

    print('PAGE MORE: $currentPage');

    try {
      List<Medecin> moreMedecins = await userRepository!.getAllMedecin(
          currentPage,
          searchLastName.text,
          searchCenter.text,
          searchSpecialite.text,
          searchLocation.text);
      if (moreMedecins.isNotEmpty) {
        currentPage++;
      }
      return moreMedecins;
    } catch (e) {
      // Gérez les erreurs de chargement de données supplémentaires ici
      return []; // ou lancez une exception appropriée selon votre logique
    }
  }

  Future<void> initializeCalendar() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Indian/Antananarivo'));

    DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();
    var calendars = await deviceCalendarPlugin.retrieveCalendars();

    if (calendars.data!.isEmpty) {
      return;
    }

    var defaultCalendarId = calendars.data!.first.id;

    try {
      List<CustomAppointment> appoints = await getProcheRendezVous(
          await userRepository!.getAllAppointmentByPatient(user!));

      if (appoints.isNotEmpty) {
        appoints.forEach((element) async {
          if (element.isDeleted == null || element.isDeleted != false) {
            TZDateTime startTZ = TZDateTime(
                tz.getLocation('Indian/Antananarivo'),
                element.startAt.year,
                element.startAt.month,
                element.startAt.day,
                element.timeStart.hour,
                element.timeStart.minute,
                element.timeStart.second);
            TZDateTime endTZ = TZDateTime(
                tz.getLocation('Indian/Antananarivo'),
                element.startAt.year,
                element.startAt.month,
                element.startAt.day,
                element.timeEnd.hour,
                element.timeEnd.minute,
                element.timeEnd.second);

            Event event = Event(
              defaultCalendarId,
              title: 'Prochain Rendez-vous: ${element.reason.toUpperCase()}',
              description: (element.medecin != null)
                  ? '${element.reason.toUpperCase()} avec le Dr ${element.medecin!.lastName} ${element.medecin!.firstName}.'
                  : element.reason,
              start: startTZ,
              end: endTZ,
              status: EventStatus.Confirmed,
              reminders: [
                Reminder(minutes: 15),
                Reminder(minutes: 30),
                Reminder(minutes: 60)
              ],
            );

            // Utiliser RetrieveEventsParams
            var params = RetrieveEventsParams(
                startDate: startTZ.subtract(const Duration(minutes: 1)),
                endDate: endTZ.add(const Duration(minutes: 1)));
            var existingEvents = await deviceCalendarPlugin.retrieveEvents(
                defaultCalendarId, params);

            var eventExists = existingEvents.data!.any((existingEvent) =>
                    existingEvent.title == event.title &&
                    existingEvent.description == event.description &&
                    existingEvent.start == startTZ &&
                    existingEvent.end == endTZ) ??
                false;

            if (!eventExists) {
              final result =
                  await deviceCalendarPlugin.createOrUpdateEvent(event);
            }
          }
        });
      }
    } catch (e, stackTrace) {}
  }

  Future<void> getAllAsync() async {
    medecinsFuture = loadMoreData();
    specialitesFuture = baseRepository!.getAllSpecialite();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }


  InitFireBase() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FireBaseTokenPatient = await FirebaseApi().initFireBase();

    sharedPreferences.setString('FireBaseTokenPatient', FireBaseTokenPatient);

    await FirebaseApi().initPushForegroundNotif();
    await FirebaseApi().initLocalNotif();
    if(FireBaseTokenPatient!=""&&FireBaseTokenPatient!=null){
      setState(() {});
      didChangeDependencies();
    }
  }

  @override
  void initState() {
    super.initState();
    utilities = Utilities(context: context);
    userRepository = UserRepository(context: context, utilities: utilities!);

    WidgetsFlutterBinding.ensureInitialized();


    InitFireBase();
  }

  List<CustomAppointment> listAppointment = [];

  ScrollController controller = ScrollController();

  List<CustomAppointment> getProcheRendezVous(
      List<CustomAppointment> rendezVousList) {
    List<CustomAppointment> rdvProche = [];

    // Implémentez ici la logique pour récupérer un rendez-vous proche
    // par rapport à la date actuelle
    DateTime now = DateTime.now();

    for (int i = 0; i < rendezVousList.length; i++) {
      CustomAppointment appointment = rendezVousList.elementAt(i);
      DateTime startDate = DateTime(
          appointment.startAt.year,
          appointment.startAt.month,
          appointment.startAt.day,
          appointment.timeStart.hour,
          appointment.timeStart.minute,
          appointment.timeStart.second);

      if (startDate.isAfter(now) &&
          isInCurrentWeek(startDate, rendezVousList.elementAt(i).timeStart)) {
        rdvProche.add(appointment);
      }
    }
    return rdvProche;
  }

  String extractApiPath(String fullPath) {
    const String apiPrefix = '/med_scheduler_api/public/api/specialities/';
    if (fullPath.startsWith(apiPrefix)) {
      return fullPath.substring(apiPrefix.length);
    } else {
      // La chaîne ne commence pas par le préfixe attendu
      return fullPath;
    }
  }

  bool isInCurrentWeek(DateTime startAt, DateTime timeStart) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day, now.hour);
    DateTime endOfWeek = startOfWeek.add(Duration(days: 7 - now.weekday));
    bool isIt = false;
    DateTime formatedStartAt =
        DateTime.parse(DateFormat('yyyy-MM-dd').format(startAt));
    DateTime formatedStartOfWeek =
        DateTime.parse(DateFormat('yyyy-MM-dd').format(startOfWeek));
    DateTime formatedEndOfWeek =
        DateTime.parse(DateFormat('yyyy-MM-dd').format(endOfWeek));
    DateTime TimeDtStart =
        DateTime(startAt.year, startAt.month, startAt.day, timeStart.hour);

    if ((formatedStartAt.isBefore(formatedEndOfWeek)) &&
        (now.subtract(const Duration(days: 1)).isBefore(TimeDtStart))) {
      isIt = true;
    }

    return isIt;
  }

  CustomAppointment? getAppointmentToday(List<CustomAppointment> list) {
    CustomAppointment? appoints;
    list.forEach((element) {
      if (DateFormat('yyyy-MM-dd').format(element.startAt) ==
          DateFormat('yyyy-MM-dd').format(
              DateTime.now().subtract(const Duration(days: 7, hours: 7)))) {
        appoints = element;
      }
    });
    return appoints;
  }

  List<CustomAppointment> filterAppointmentsForCurrentWeek(
      List<CustomAppointment> appointmentFuture) {
    DateTime now = DateTime.now();

    List<CustomAppointment> filteredAppointments = [];

    // Attendre la résolution du Future<List<CustomAppointment>>
    List<CustomAppointment> appointments = appointmentFuture;

    // Filtrer les appointments de la semaine actuelle
    List<CustomAppointment> appointmentsInCurrentWeek =
        appointments.where((appointment) {
      return isInCurrentWeek(appointment.startAt, appointment.timeStart);
    }).toList();

    String nowFormatted = DateFormat('yyyy-MM-dd HH').format(now);

    // Ajouter les appointments filtrés à la liste résultante
    filteredAppointments.addAll(appointmentsInCurrentWeek.where((element) {
      String dtAppointFormatted = DateFormat('yyyy-MM-dd HH').format(DateTime(
          element.startAt.year,
          element.startAt.month,
          element.startAt.day,
          element.timeStart.hour));
      DateTime dtNow = DateTime.parse(nowFormatted);
      DateTime dtAppoint = DateTime.parse(dtAppointFormatted);
      return dtAppoint.isAfter(dtNow);
    }));

    return filteredAppointments;
  }

  //Fonction pour stocker les categories trouvés
  void getAll() {
    userRepository!.getAllAppointmentByPatient(user!).then((value) => {
          setState(() {
            listAppointment = value;
          })
        });
    baseRepository!.getAllSpecialite().then((value) => {
          setState(() {
            listSpec = value;
          })
        });

    baseRepository!.getAllCenter().then((value) => {
          setState(() {
            listCenter = value;
          })
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authProvider = Provider.of<AuthProvider>(context,listen: false);
    token = authProvider.token;
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      await getAllAsync();

      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      String? tokenFromFireBase = sharedPreferences.getString('FireBaseTokenPatient');
      if(tokenFromFireBase!=null&&tokenFromFireBase!=""){
        Map<String, dynamic> payload = Jwt.parseJwt(token);
        idUser = payload['id'] ?? '';
        dataLoaded = true;

        Utilisateur patientWithToken = Utilisateur(
            id: user!.id,
            imageName: (user!.imageName != null && user!.imageName != "")
                ? utilities!.extraireNomFichier(user!.imageName!)
          : '',
      lastName: user!.lastName,
      firstName: user!.firstName,
      userType: user!.userType,
      phone: user!.phone,
      password: user!.password,
      email: user!.email,
      category: user!.category,
      address: user!.address,
      roles: user!.roles,
      city: user!.city,
      token: tokenFromFireBase);

      userRepository!.updatePatient(patientWithToken);

      patient = Patient(
      token: patientWithToken.token,
      id: user!.id,
      type: user!.userType,
      lastName: user!.lastName,
      firstName: user!.firstName);
      }else{
        InitFireBase();
      }


    });
    baseRepository = BaseRepository(context: context, utilities: utilities!);
    user = Provider.of<AuthProviderUser>(context,listen: false).utilisateur;
    initializeCalendar();
    if (mounted) {
      getAll();
      print('LOADED: $dataLoaded');
    }
  }

  String abbreviateName(String fullName) {
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length == 1) {
      // Si le nom ne contient qu'un seul mot, renvoyer le nom tel quel
      return fullName;
    } else {
      // Si le nom contient plusieurs mots
      String firstName = nameParts.first;

      if (nameParts.length > 1) {
        // Si le prénom contient plus de deux mots, utiliser seulement le premier mot
        return "$firstName ${nameParts[1]}";
      } else {
        // Sinon, construire l'abréviation en prenant la première lettre du premier mot
        // et le nom complet du deuxième mot
        String lastName = nameParts.last;
        String abbreviation = "${firstName[0]}.$lastName";
        return abbreviation;
      }
    }
  }

  String abreviateRaison(String fullName) {
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length == 1) {
      // Si le nom ne contient qu'un seul mot, renvoyer le nom tel quel
      return fullName;
    }
    if (nameParts.length > 1) {
      // Si le prénom contient plus de deux mots, utiliser seulement le premier mot
      return "${nameParts[0]}...";
    } else {
      return fullName;
    }
  }

  String formatDateTime(DateTime startDateTime) {
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
    int heure = startDateTime.hour;
    int minute = startDateTime.minute;

    // Formater le jour de la semaine
    String jourSemaine = jours[startDateTime.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Formater l'heure
    String formatHeure =
        '${heure.toString().padLeft(2, '0')}h:${minute.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat = '$jourSemaine, $jour $nomMois  $formatHeure';

    return resultat;
  }

  String formatDateTimeAppointmentAgenda(
      DateTime startAt, DateTime startDateTime, DateTime timeEnd) {
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

    int jour = startAt.day;
    int moisIndex = startAt.month;
    int annee = startDateTime.year;
    int heureStart = startDateTime.hour;
    int minuteStart = startDateTime.minute;
    int heureEnd = timeEnd.hour;
    int minuteEnd = timeEnd.minute;

    // Formater le jour de la semaine
    String jourSemaine = jours[startAt.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Formater l'heure
    String formatHeureStart =
        '${heureStart.toString().padLeft(2, '0')}:${minuteStart.toString().padLeft(2, '0')}';
    String formatHeureEnd =
        '${heureEnd.toString().padLeft(2, '0')}:${minuteEnd.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat = '$formatHeureStart - $formatHeureEnd';

    return resultat;
  }

  String formatDateTimeAppointment(
      DateTime startAt, DateTime startDateTime, DateTime timeEnd) {
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

    int jour = startAt.day;
    int moisIndex = startAt.month;
    int annee = startDateTime.year;
    int heureStart = startDateTime.hour;
    int minuteStart = startDateTime.minute;
    int heureEnd = timeEnd.hour;
    int minuteEnd = timeEnd.minute;

    // Formater le jour de la semaine
    String jourSemaine = jours[startAt.weekday - 1];

    // Formater le mois
    String nomMois = mois[moisIndex];

    // Formater l'heure
    String formatHeureStart =
        '${heureStart.toString().padLeft(2, '0')}:${minuteStart.toString().padLeft(2, '0')}';
    String formatHeureEnd =
        '${heureEnd.toString().padLeft(2, '0')}:${minuteEnd.toString().padLeft(2, '0')}';

    // Construire la chaîne lisible
    String resultat =
        '$jourSemaine, $jour $nomMois  $formatHeureStart-$formatHeureEnd';

    return resultat;
  }

  Color generateRandomColor() {
    Random random = Random();

    // Générer des valeurs aléatoires pour les composants ARGB
    int alpha = 40; // Opacité maximale
    int red = random.nextInt(250);
    int green = random.nextInt(250);
    int blue = random.nextInt(250);

    // Créer et retourner la couleur générée
    return Color.fromARGB(alpha, red, green, blue);
  }

  FocusNode _focusNodeSearch = FocusNode();
  FocusNode _focusNodeSearchCenter = FocusNode();
  FocusNode _focusNodeSearchSpec = FocusNode();
  FocusNode _focusNodeSearchLoc = FocusNode();

  Widget CardNothing() => Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: const Card(
          color: Color.fromARGB(1000, 60, 70, 120),
          child: Column(children: [
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Padding(padding: EdgeInsets.only(bottom: 10),child: Text(
                        'Aucun rendez-vous pour cette semaine',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            letterSpacing: 2),
                      ),
                      ),
                      Center(
                        child: Icon(
                          Icons.update,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Spacer()
          ])));

  Widget BuildCard(CustomAppointment appointment) => GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AppointmentDetails(),
                  settings: RouteSettings(arguments: appointment)));
        },
        child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Card(
                color: const Color.fromARGB(1000, 60, 70, 120),
                child: Column(children: [
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: CachedNetworkImage(
                            imageUrl:
                                '$baseUrl${utilities!.ajouterPrefixe(appointment.medecin!.imageName!)}',
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(
                              color: Colors.redAccent,
                            ), // Affiche un indicateur de chargement en attendant l'image
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/medecin.png',
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                            ), // Affiche une icône d'erreur si le chargement échoue
                          ),
                        ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr ${appointment.medecin!.lastName[0]}.${abbreviateName(appointment.medecin!.firstName)}',
                              overflow: TextOverflow.fade,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${abreviateRaison(appointment.reason)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                  fontSize: 15),
                            )
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AppointmentDetails(),
                                  settings:
                                      RouteSettings(arguments: appointment)));
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_right_sharp,
                          size: 50,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                  const Opacity(
                    opacity: 0.4,
                    child: Divider(
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Colors.white70,
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Image.asset(
                          'assets/images/date-limite.png',
                          width: 30,
                        ),
                      ),
                      Spacer()
                    ],
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20, top: 5),
                        child: Text(
                          '${formatDateTimeAppointment(appointment.startAt, appointment.timeStart, appointment.timeEnd)} ',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Spacer()
                    ],
                  )
                ]))),
      );

  bool isCenter = false;
  bool isSpecialite = false;
  bool isLocation = false;

  bool isloading = false;

  bool medEmpty = false;

  List<Centre> listCenter = [];
  List<Specialite> listSpec = [];

  Specialite? speciality;
  Centre? centre;

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      child: Scaffold(
          backgroundColor: const Color.fromARGB(1000, 238, 239, 244),
          body: ((mounted) && (dataLoaded == true))
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Column(
                              children: [
                                const Opacity(
                                  opacity: 0.5,
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    textScaler: TextScaler.linear(1.3),
                                    'Bonjour,',
                                    style: TextStyle(
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  textAlign: TextAlign.center,
                                  textScaler: const TextScaler.linear(1.45),
                                  '${user!.firstName ?? 'Chargement...'}',
                                  style: const TextStyle(
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(230, 20, 20, 90),
                                  ),
                                ),
                              ],
                            )),
                        const Spacer(),
                        Padding(
                            padding: const EdgeInsets.only(right: 15, top: 20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Container(
                                width: 60,
                                height: 60,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      '$baseUrl${utilities!.ajouterPrefixe(user!.imageName!)}',
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(
                                    color: Colors.redAccent,
                                  ), // Affiche un indicateur de chargement en attendant l'image
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                    'assets/images/Medhome.png',
                                    fit: BoxFit.cover,
                                    width: 50,
                                    height: 50,
                                  ), // Affiche une icône d'erreur si le chargement échoue
                                ),
                              ),
                            ))
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: CarouselSlider.builder(
                        itemCount:
                            filterAppointmentsForCurrentWeek(listAppointment)
                                .length,
                        itemBuilder: (context, i, index) {
                          return GestureDetector(
                              onTap: () async {},
                              child: (filterAppointmentsForCurrentWeek(
                                          listAppointment)
                                      .isNotEmpty)
                                  ? BuildCard(filterAppointmentsForCurrentWeek(
                                          listAppointment)
                                      .elementAt(i))
                                  : CardNothing());
                        },
                        options: CarouselOptions(
                            height: isLandscape ? 60 : 190,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            enlargeStrategy: CenterPageEnlargeStrategy.height),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 30, right: 30, bottom: 10, top: 10),
                      child: TextFormField(
                        onChanged: (nom) {
                          if (nom.trim().isEmpty) {
                            setState(() {
                              searchLastName.text = "";
                              medecinsFuture = userRepository!.getAllMedecin(
                                  currentPage,
                                  searchLastName.text,
                                  searchCenter.text,
                                  searchSpecialite.text,
                                  searchLocation.text);
                            });
                          } else {
                            setState(() {
                              searchLastName.text = nom;
                              medecinsFuture = userRepository!.getAllMedecin(
                                  currentPage,
                                  searchLastName.text,
                                  searchCenter.text,
                                  searchSpecialite.text,
                                  searchLocation.text);
                            });
                          }
                        },
                        focusNode: _focusNodeSearch,
                        controller: searchLastName,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          focusColor: const Color.fromARGB(255, 20, 20, 100),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                width: 0,
                                color: Color.fromARGB(255, 20, 20, 100)),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          hintStyle: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w300),

                          hintText: 'Rechercher un medecin ',
                          labelStyle: TextStyle(
                              color: _focusNodeSearch.hasFocus
                                  ? Colors.redAccent
                                  : Colors.black),
                          border: InputBorder
                              .none, // Utilisez InputBorder.none pour supprimer la bordure
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(width: 0, color: Colors.grey),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          prefixIcon: const Icon(Icons.search,
                              color: Color.fromARGB(1000, 60, 70, 120)),
                        ),
                      ),
                    ),
                    Expanded(
                        child: SingleChildScrollView(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                speciality = null;
                                searchCenter.text = "";
                                searchSpecialite.text = "";
                                searchLocation.text = "";
                                isLocation = false;
                                isSpecialite = false;
                                isCenter = !isCenter;
                                if (isCenter == false) {
                                  centre = null;
                                  searchCenter.text = "";
                                  setState(() {
                                    medecinsFuture = userRepository!
                                        .getAllMedecin(
                                            currentPage,
                                            searchLastName.text,
                                            searchCenter.text,
                                            searchSpecialite.text,
                                            searchLocation.text);
                                  });
                                }
                              });
                            },
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          1000, 230, 230, 230),
                                      border: isCenter
                                          ? Border.all(color: Colors.black)
                                          : null,
                                    ),
                                    width: 80,
                                    height: 80,
                                    child: const Icon(
                                      Icons.home_work_rounded,
                                      color: Color.fromARGB(1000, 60, 70, 120),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Centre',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                centre = null;
                                searchSpecialite.text = "";
                                searchCenter.text = "";
                                isCenter = false;
                                isLocation = false;
                                searchLocation.text = "";
                                isSpecialite = !isSpecialite;
                                if (isSpecialite == false) {
                                  speciality = null;
                                  searchSpecialite.text = "";
                                  setState(() {
                                    medecinsFuture = userRepository!
                                        .getAllMedecin(
                                            currentPage,
                                            searchLastName.text,
                                            searchCenter.text,
                                            searchSpecialite.text,
                                            searchLocation.text);
                                  });
                                }
                              });
                            },
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          1000, 230, 230, 230),
                                      border: isSpecialite
                                          ? Border.all(color: Colors.black)
                                          : null,
                                    ),
                                    width: 80,
                                    height: 80,
                                    child: const Icon(
                                      FontAwesome.user_doctor,
                                      color: Color.fromARGB(1000, 60, 70, 120),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Specialite',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                centre = null;
                                speciality = null;
                                searchCenter.text = "";
                                searchSpecialite.text = "";
                                isCenter = false;
                                isSpecialite = false;
                                isLocation = !isLocation;

                                if (isLocation == false) {
                                  medecinsFuture = userRepository!
                                      .getAllMedecin(
                                          currentPage,
                                          searchLastName.text,
                                          searchCenter.text,
                                          searchSpecialite.text,
                                          searchLocation.text);
                                }
                              });
                            },
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          1000, 230, 230, 230),
                                      border: isLocation
                                          ? Border.all(
                                              color: Colors.black,
                                            )
                                          : null,
                                    ),
                                    width: 80,
                                    height: 80,
                                    child: const Icon(
                                      FontAwesome.location_dot,
                                      color: Color.fromARGB(1000, 60, 70, 120),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Localisation',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (isCenter) ...[
                      Expanded(
                          child: Padding(
                        padding:
                            const EdgeInsets.only(right: 30, left: 30, top: 20),
                        child: DropdownButtonFormField<Centre>(
                          focusNode: _focusNodeSearchCenter,
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Icon(
                              Icons.arrow_drop_down_circle_outlined,
                              color: Colors.black,
                            ),
                          ),
                          value: centre,
                          onChanged: (Centre? newval) {
                            setState(() {
                              searchSpecialite.text = "";
                              centre = newval!;
                              searchCenter.text = centre!.label;

                              medecinsFuture = userRepository!.getAllMedecin(
                                  currentPage,
                                  searchLastName.text,
                                  searchCenter.text,
                                  searchSpecialite.text,
                                  searchLocation.text);
                            });
                          },
                          items: listCenter.map((e) {
                            return DropdownMenuItem<Centre>(
                              key: Key(e.id),
                              value: e,
                              child: Text(e.label),
                            );
                          }).toList(),
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    width: 0,
                                    color: Color.fromARGB(255, 20, 20, 100)),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    width: 0, color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: const Icon(
                                Icons.people,
                                color: Color.fromARGB(1000, 60, 70, 120),
                              ),
                              labelStyle: TextStyle(
                                  color: _focusNodeSearchCenter.hasFocus
                                      ? Colors.redAccent
                                      : Colors.black),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                              hintText: (searchCenter.text != "")
                                  ? ''
                                  : 'Liste des center',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0))),
                        ),
                      ))
                    ] else if (isSpecialite) ...[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 30, left: 30, top: 20),
                          child: DropdownButtonFormField<Specialite>(
                            itemHeight: 50,
                            focusNode: _focusNodeSearchSpec,
                            icon: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.arrow_drop_down_circle_outlined,
                                color: Colors.black,
                              ),
                            ),
                            value: speciality,
                            onChanged: (Specialite? newval) {

                              setState(() {
                                searchCenter.text = "";
                                speciality = newval!;
                                searchSpecialite.text = speciality!.label;
                                medecinsFuture = userRepository!.getAllMedecin(
                                    currentPage,
                                    searchLastName.text,
                                    searchCenter.text,
                                    searchSpecialite.text,
                                    searchLocation.text);
                              });
                            },
                            items: listSpec.map((e) {
                              return DropdownMenuItem<Specialite>(
                                key: Key(e.id),
                                value: e,
                                child: Text(e.label),
                              );
                            }).toList(),
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 0),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      width: 0,
                                      color: Color.fromARGB(255, 20, 20, 100)),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      width: 0, color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                prefixIcon: const Icon(
                                  Icons.people,
                                  color: Color.fromARGB(1000, 60, 70, 120),
                                ),
                                labelStyle: TextStyle(
                                    color: _focusNodeSearchSpec.hasFocus
                                        ? Colors.redAccent
                                        : Colors.black),
                                hintStyle: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w300),
                                hintText: (searchSpecialite.text != "")
                                    ? ''
                                    : 'Liste des specialites',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0))),
                          ),
                        ),
                      )
                    ] else if (isLocation) ...[
                      Expanded(
                        flex: (_focusNodeSearchLoc.hasFocus) ? 8 : 1,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 30, right: 30, top: 20),
                          child: TextFormField(
                            onChanged: (nom) {
                              if (nom.trim().isEmpty) {
                                setState(() {
                                  searchCenter.text = "";
                                  searchSpecialite.text = "";
                                  searchLastName.text = "";
                                  medecinsFuture = userRepository!
                                      .getAllMedecin(
                                          currentPage,
                                          searchLastName.text,
                                          searchCenter.text,
                                          searchSpecialite.text,
                                          searchLocation.text);
                                });
                              } else {
                                setState(() {
                                  searchCenter.text = "";
                                  searchSpecialite.text = "";
                                  searchLocation.text =
                                      (nom.isNotEmpty) ? nom : '';
                                  medecinsFuture = userRepository!
                                      .getAllMedecin(
                                          currentPage,
                                          searchLastName.text,
                                          searchCenter.text,
                                          searchSpecialite.text,
                                          searchLocation.text);
                                });
                              }
                            },
                            focusNode: _focusNodeSearchLoc,
                            controller: searchLocation,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              focusColor:
                                  const Color.fromARGB(255, 20, 20, 100),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    width: 0,
                                    color: Color.fromARGB(255, 20, 20, 100)),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              hintStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),

                              hintText: 'Rechercher la localisation ',
                              labelStyle: TextStyle(
                                  color: _focusNodeSearch.hasFocus
                                      ? Colors.redAccent
                                      : Colors.black),
                              border: InputBorder
                                  .none, // Utilisez InputBorder.none pour supprimer la bordure
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    width: 0, color: Colors.grey),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: const Icon(Icons.search,
                                  color: Color.fromARGB(1000, 60, 70, 120)),
                            ),
                          ),
                        ),
                      )
                    ],
                    Expanded(
                        flex: 3,
                        child: FutureBuilder<List<Medecin>>(
                          future: medecinsFuture,
                          builder: (context, medecinsSnapshot) {
                            if (medecinsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: ListView(
                                children: const [
                                  Center(
                                      child: CircularProgressIndicator(
                                    color: Colors.redAccent,
                                  )),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Text(
                                    'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ));
                            } else if (medecinsSnapshot.hasError) {
                              return Center(
                                child:
                                    Text('Erreur: ${medecinsSnapshot.error}'),
                              );
                            } else {
                              List<Medecin> medecins = medecinsSnapshot.data!;

                              if (medecins.isEmpty) {
                                return Padding(
                                    padding: const EdgeInsets.only(
                                        right: 18,
                                        left: 18,
                                        top: 20,
                                        bottom: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(23),
                                      child: Container(
                                        height: 170,
                                        child: Card(
                                          elevation: 0.5,
                                          color: Colors.white,
                                          child: ListView(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 20,
                                                    top: 10,
                                                    right: 50),
                                                child: Text(
                                                  'Merci de rechercher les médecins avec les options ci-dessus...',
                                                  style: TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.grey
                                                          .withOpacity(0.9),
                                                      letterSpacing: 2),
                                                ),
                                              ),
                                              const Opacity(
                                                opacity: 0.4,
                                                child: Divider(
                                                  thickness: 1,
                                                  indent: 20,
                                                  endIndent: 20,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ));
                              }

                              return NotificationListener(
                                  onNotification:
                                      (ScrollNotification scrollInfo) {
                                    if (scrollInfo is ScrollEndNotification &&
                                        scrollController.position.extentAfter ==
                                            0) {
                                      // L'utilisateur a atteint la fin de la liste, chargez plus de données
                                      loadMoreData();
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                  physics: BouncingScrollPhysics(),
                                    controller: scrollController,
                                    itemCount:
                                        medecins.length + (isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      Medecin medecin = medecins[index];

                                      if (index < medecins.length) {
                                        return Padding(
                                            padding: const EdgeInsets.only(
                                                right: 18,
                                                left: 18,
                                                bottom: 10),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(23),
                                              child: Container(
                                                height: 200,
                                                child: Card(
                                                  elevation: 0.5,
                                                  color: Colors.white,
                                                  child: Column(
                                                    children: [
                                                      const Spacer(),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          const SizedBox(
                                                            width: 20,
                                                          ),
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        50),
                                                            child: Container(
                                                              width: 60,
                                                              height: 60,
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            60),
                                                              ),
                                                              child:
                                                                  CachedNetworkImage(
                                                                imageUrl:
                                                                    '$baseUrl${utilities!.ajouterPrefixe(medecin.imageName!)}',
                                                                placeholder: (context,
                                                                        url) =>
                                                                    const CircularProgressIndicator(
                                                                  color: Colors
                                                                      .redAccent,
                                                                ), // Affiche un indicateur de chargement en attendant l'image
                                                                errorWidget: (context,
                                                                        url,
                                                                        error) =>
                                                                    Image.asset(
                                                                  'assets/images/medecin.png',
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  width: 50,
                                                                  height: 50,
                                                                ), // Affiche une icône d'erreur si le chargement échoue
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Column(
                                                            children: [
                                                              Text(
                                                                'Dr ${medecin.lastName[0]}.${abbreviateName(medecin.firstName)}',
                                                                overflow:
                                                                    TextOverflow
                                                                        .fade,
                                                                style: const TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            1000,
                                                                            60,
                                                                            70,
                                                                            120),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              ),
                                                              Text(
                                                                '${(medecin.speciality != null) ? medecin.speciality!.label : ''}',
                                                                style: const TextStyle(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            1000,
                                                                            60,
                                                                            70,
                                                                            120),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300),
                                                              )
                                                            ],
                                                          ),
                                                          const Spacer()
                                                        ],
                                                      ),
                                                      const Opacity(
                                                        opacity: 0.4,
                                                        child: Divider(
                                                          thickness: 1,
                                                          indent: 20,
                                                          endIndent: 20,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 30,
                                                                    right: 10),
                                                            child: Image.asset(
                                                              'assets/images/date-limite.png',
                                                              width: 30,
                                                              height: 30,
                                                            ),
                                                          ),
                                                          const Text(
                                                            '5rdv/jour',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                                color: Color
                                                                    .fromARGB(
                                                                        1000,
                                                                        60,
                                                                        70,
                                                                        120)),
                                                          ),
                                                          const Spacer(),
                                                          const Icon(
                                                            Icons.watch_later,
                                                            color: Colors
                                                                .redAccent,
                                                          ),
                                                          const Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 5,
                                                                    right: 15),
                                                            child: Text(
                                                              'Disponible de 08:00',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                  color: Color
                                                                      .fromARGB(
                                                                          1000,
                                                                          60,
                                                                          70,
                                                                          120)),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                      Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 15.0,
                                                                  left: 10,
                                                                  right: 10,
                                                                  bottom: 15),
                                                          child: ElevatedButton(
                                                            style: ButtonStyle(
                                                              backgroundColor:
                                                                  MaterialStateProperty.all(
                                                                      const Color
                                                                          .fromARGB(
                                                                          1000,
                                                                          60,
                                                                          70,
                                                                          120)),
                                                              shape:
                                                                  MaterialStateProperty
                                                                      .all(
                                                                RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8.0), // Définissez le rayon de la bordure ici
                                                                ),
                                                              ),
                                                              minimumSize:
                                                                  MaterialStateProperty.all(
                                                                      const Size(
                                                                          180.0,
                                                                          40.0)),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pushReplacement(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) => PriseDeRendezVous(
                                                                          patient:
                                                                              patient!),
                                                                      settings: RouteSettings(
                                                                          arguments:
                                                                              medecin)));
                                                            },
                                                            child: const Text(
                                                              'Prendre un rendez-vous',
                                                              textScaleFactor:
                                                                  1.2,
                                                              style: TextStyle(
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        253,
                                                                        253,
                                                                        253),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          )),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ));
                                      } else if (isLoading) {
                                        // Affichez l'indicateur de chargement pendant le chargement des données
                                        return Center(
                                            child: LoadingAnimationWidget
                                                .fourRotatingDots(
                                                    color: Colors.redAccent,
                                                    size: 120));
                                      } else {
                                        return Container(); // ou tout autre widget pour l'espace réservé
                                      }
                                    },
                                  ));
                            }
                          },
                        ))
                  ],
                )
              : Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    loadingWidget(),
                    const SizedBox(
                      height: 30,
                    ),
                    const Text(
                      'Chargement des données..\n Assurez-vous d\'avoir une connexion internet',
                      textAlign: TextAlign.center,
                    )
                  ],
                ))),
    );
  }

  Widget loadingWidget() {
    return Center(
        child: Container(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          LoadingAnimationWidget.hexagonDots(
              color: Colors.redAccent, size: 120),
          Image.asset(
            'assets/images/logo2.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          )
        ],
      ),
    ));
  }
}
