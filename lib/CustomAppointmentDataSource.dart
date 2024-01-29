import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'CustomAppointment.dart';
import 'package:flutter/material.dart';
import 'Medecin.dart';
import 'Patient.dart';

class CustomAppointmentDataSource extends CalendarDataSource{


  CustomAppointmentDataSource(List<CustomAppointment> source) {
    appointments = source;
  }


  String getId(int index){
    return _getMeetingData(index).id;
  }

  String getType(int index){
    return _getMeetingData(index).type;
  }

  String getCategorie(int index){
    return _getMeetingData(index).appType!;
  }

  Medecin getMedecin(int index) {

    Medecin med = _getMeetingData(index).medecin!;
    print('MED: ${med.lastName}, ${med.firstName}');
    return med;
  }
  Patient getPatient(int index) {
    return _getMeetingData(index).patient!;
  }

  DateTime getCreated_At(int index) {
    return _getMeetingData(index).createdAt;
  }


  DateTime getStartAt(int index) {

    return _getMeetingData(index).startAt;
  }

  @override
  DateTime getStartTime(int index) {
    DateTime start = _getMeetingData(index).timeStart;
    DateTime startDate = DateTime(getStartAt(index).year,getStartAt(index).month,getStartAt(index).day,start.hour,start.minute);

    return startDate;
  }

  @override
  DateTime getEndTime(int index) {
    DateTime end = _getMeetingData(index).timeEnd;
    DateTime endDate = DateTime(getStartAt(index).year,getStartAt(index).month,getStartAt(index).day,end.hour,end.minute);

    return endDate;
  }

  @override
  String getSubject(int index) {
    String subject = _getMeetingData(index).reason;

    return subject;
  }

  @override
  Color getColor(int index) {
    Color color = _getMeetingData(index).color;

    return color;
  }

  @override
  bool isAllDay(int index) {
    return false;
  }

  @override
  List<CustomAppointment> appointmentsInRange(
      DateTime startDate, DateTime endDate) {
    final List<CustomAppointment> visibleAppointments = [];
    for (int i = 0; i < appointments!.length; i++) {
      final CustomAppointment appointment = _getMeetingData(i);
      if ((appointment.startAt.isAfter(startDate) ||
          appointment.startAt.isAtSameMomentAs(startDate)) &&
          (appointment.startAt.isBefore(endDate) ||
              appointment.startAt.isAtSameMomentAs(endDate))) {
        visibleAppointments.add(appointment);
      }
    }
    return visibleAppointments;
  }



  CustomAppointment _getMeetingData(int index) {
    final dynamic meeting = appointments![index];
    late final CustomAppointment meetingData;
    if (meeting is CustomAppointment) {
      meetingData = meeting;
    }

    return meetingData;
  }
}