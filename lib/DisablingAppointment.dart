import 'CustomAppointment.dart';
import 'Medecin.dart';


class DisablingAppointment{
  DateTime jourCliquer;
  Medecin medecin;
  List<CustomAppointment> appoints;

  DisablingAppointment({required this.jourCliquer,required this.medecin,required this.appoints});


  void setAppointments(List<CustomAppointment> newAppointments){
    appoints = newAppointments;
  }

  List<CustomAppointment> getAppointment(){
    return appoints;
  }

}