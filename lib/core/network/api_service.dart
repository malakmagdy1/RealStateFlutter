import 'package:real/feature/auth/data/repositories/auth_repository.dart';
import 'package:real/feature/auth/data/web_services/auth_web_services.dart';
import 'package:real/feature/company/data/repositories/company_repository.dart';
import 'package:real/feature/company/data/web_services/company_web_services.dart';
import 'package:real/feature/compound/data/repositories/compound_repository.dart';
import 'package:real/feature/compound/data/repository/unit_repository.dart';
import 'package:real/feature/compound/data/web_services/compound_web_services.dart';
import 'package:real/feature/compound/data/web_services/unit_web_services.dart';
import 'package:real/feature/sale/data/repositories/sale_repository.dart';
import 'package:real/feature/sale/data/services/sale_web_services.dart';
import 'package:real/feature/subscription/data/repositories/subscription_repository.dart';
import 'package:real/feature/subscription/data/web_services/subscription_web_services.dart';

class ApiService {
  late final AuthWebServices authWebServices;
  late final AuthRepository authRepository;
  late final CompanyWebServices companyWebServices;
  late final CompanyRepository companyRepository;
  late final CompoundWebServices compoundWebServices;
  late final CompoundRepository compoundRepository;
  late final UnitWebServices unitWebServices;
  late final UnitRepository unitRepository;
  late final SaleWebServices saleWebServices;
  late final SaleRepository saleRepository;
  late final SubscriptionWebServices subscriptionWebServices;
  late final SubscriptionRepository subscriptionRepository;

  ApiService() {
    authWebServices = AuthWebServices();
    authRepository = AuthRepository(authWebServices: authWebServices);
    companyWebServices = CompanyWebServices();
    companyRepository = CompanyRepository(
      companyWebServices: companyWebServices,
    );
    compoundWebServices = CompoundWebServices();
    compoundRepository = CompoundRepository(
      compoundWebServices: compoundWebServices,
    );
    unitWebServices = UnitWebServices();
    unitRepository = UnitRepository(webServices: unitWebServices);
    saleWebServices = SaleWebServices();
    saleRepository = SaleRepository(webServices: saleWebServices);
    subscriptionWebServices = SubscriptionWebServices();
    subscriptionRepository = SubscriptionRepository(
      webServices: subscriptionWebServices,
    );
  }
}
