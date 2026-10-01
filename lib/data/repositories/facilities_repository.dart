import '../local/dao/emergency_contact_dao.dart';
import '../local/dao/emergency_service_dao.dart';
import '../local/dao/hospital_dao.dart';
import '../local/dao/resource_dao.dart';
import '../local/dao/safe_zone_dao.dart';
import '../local/dao/shelter_dao.dart';
import '../local/models/emergency_contact_model.dart';
import '../local/models/emergency_service_model.dart';
import '../local/models/hospital_model.dart';
import '../local/models/resource_model.dart';
import '../local/models/safe_zone_model.dart';
import '../local/models/shelter_model.dart';

class FacilitiesRepository {
  final ShelterDao _shelterDao;
  final HospitalDao _hospitalDao;
  final EmergencyServiceDao _serviceDao;
  final EmergencyContactDao _contactDao;
  final SafeZoneDao _safeZoneDao;
  final ResourceDao _resourceDao;

  FacilitiesRepository({
    ShelterDao? shelterDao,
    HospitalDao? hospitalDao,
    EmergencyServiceDao? serviceDao,
    EmergencyContactDao? contactDao,
    SafeZoneDao? safeZoneDao,
    ResourceDao? resourceDao,
  })  : _shelterDao = shelterDao ?? ShelterDao(),
        _hospitalDao = hospitalDao ?? HospitalDao(),
        _serviceDao = serviceDao ?? EmergencyServiceDao(),
        _contactDao = contactDao ?? EmergencyContactDao(),
        _safeZoneDao = safeZoneDao ?? SafeZoneDao(),
        _resourceDao = resourceDao ?? ResourceDao();

  Future<List<ShelterModel>> getShelters() => _shelterDao.getAll();
  Future<List<ShelterModel>> getOpenShelters() => _shelterDao.getOpenShelters();
  Future<List<HospitalModel>> getHospitals() => _hospitalDao.getAll();
  Future<List<EmergencyServiceModel>> getEmergencyServices() => _serviceDao.getAll();
  Future<List<EmergencyContactModel>> getEmergencyContacts() => _contactDao.getAll();
  Future<List<SafeZoneModel>> getSafeZones() => _safeZoneDao.getAll();
  Future<List<ResourceModel>> getResources() => _resourceDao.getAll();

  Future<void> addContact(EmergencyContactModel contact) => _contactDao.insert(contact);
  Future<void> addShelter(ShelterModel shelter) => _shelterDao.insert(shelter);
  Future<void> addHospital(HospitalModel hospital) => _hospitalDao.insert(hospital);
  Future<void> addSafeZone(SafeZoneModel zone) => _safeZoneDao.insert(zone);
}
