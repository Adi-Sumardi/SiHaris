/// Model untuk identitas perusahaan pada bukti potong
class TaxFormCompanyInfo {
  final String? npwp;
  final String name;
  final String? address;

  const TaxFormCompanyInfo({
    this.npwp,
    required this.name,
    this.address,
  });

  factory TaxFormCompanyInfo.fromJson(Map<String, dynamic> json) {
    return TaxFormCompanyInfo(
      npwp: json['npwp'],
      name: json['name'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'npwp': npwp,
      'name': name,
      'address': address,
    };
  }
}

/// Model untuk identitas karyawan pada bukti potong
class TaxFormEmployeeInfo {
  final String? npwp;
  final String? nik;
  final String name;
  final String? address;
  final String ptkpStatus;

  const TaxFormEmployeeInfo({
    this.npwp,
    this.nik,
    required this.name,
    this.address,
    required this.ptkpStatus,
  });

  factory TaxFormEmployeeInfo.fromJson(Map<String, dynamic> json) {
    return TaxFormEmployeeInfo(
      npwp: json['npwp'],
      nik: json['nik'],
      name: json['name'],
      address: json['address'],
      ptkpStatus: json['ptkp_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'npwp': npwp,
      'nik': nik,
      'name': name,
      'address': address,
      'ptkp_status': ptkpStatus,
    };
  }
}

/// Model untuk penghasilan bruto
class PenghasilanBruto {
  final double gajiPokok;
  final double tunjanganPph;
  final double tunjanganLainnya;
  final double honorarium;
  final double premiAsuransi;
  final double natura;
  final double tantiemBonusThr;
  final double grossSalary;

  const PenghasilanBruto({
    required this.gajiPokok,
    required this.tunjanganPph,
    required this.tunjanganLainnya,
    required this.honorarium,
    required this.premiAsuransi,
    required this.natura,
    required this.tantiemBonusThr,
    required this.grossSalary,
  });

  factory PenghasilanBruto.fromJson(Map<String, dynamic> json) {
    return PenghasilanBruto(
      gajiPokok: (json['gaji_pokok'] as num).toDouble(),
      tunjanganPph: (json['tunjangan_pph'] as num).toDouble(),
      tunjanganLainnya: (json['tunjangan_lainnya'] as num).toDouble(),
      honorarium: (json['honorarium'] as num).toDouble(),
      premiAsuransi: (json['premi_asuransi'] as num).toDouble(),
      natura: (json['natura'] as num).toDouble(),
      tantiemBonusThr: (json['tantiem_bonus_thr'] as num).toDouble(),
      grossSalary: (json['gross_salary'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gaji_pokok': gajiPokok,
      'tunjangan_pph': tunjanganPph,
      'tunjangan_lainnya': tunjanganLainnya,
      'honorarium': honorarium,
      'premi_asuransi': premiAsuransi,
      'natura': natura,
      'tantiem_bonus_thr': tantiemBonusThr,
      'gross_salary': grossSalary,
    };
  }
}

/// Model untuk pengurang penghasilan
class Pengurang {
  final double biayaJabatan;
  final double iuranPensiun;
  final double totalPengurang;

  const Pengurang({
    required this.biayaJabatan,
    required this.iuranPensiun,
    required this.totalPengurang,
  });

  factory Pengurang.fromJson(Map<String, dynamic> json) {
    return Pengurang(
      biayaJabatan: (json['biaya_jabatan'] as num).toDouble(),
      iuranPensiun: (json['iuran_pensiun'] as num).toDouble(),
      totalPengurang: (json['total_pengurang'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biaya_jabatan': biayaJabatan,
      'iuran_pensiun': iuranPensiun,
      'total_pengurang': totalPengurang,
    };
  }
}

/// Model untuk perhitungan PPh 21
class PerhitunganPph {
  final double netoSalary;
  final double ptkp;
  final double pkp;
  final double pph21Terutang;
  final double pph21DipotongSebelumnya;
  final double totalPph21Withheld;

  const PerhitunganPph({
    required this.netoSalary,
    required this.ptkp,
    required this.pkp,
    required this.pph21Terutang,
    required this.pph21DipotongSebelumnya,
    required this.totalPph21Withheld,
  });

  factory PerhitunganPph.fromJson(Map<String, dynamic> json) {
    return PerhitunganPph(
      netoSalary: (json['neto_salary'] as num).toDouble(),
      ptkp: (json['ptkp'] as num).toDouble(),
      pkp: (json['pkp'] as num).toDouble(),
      pph21Terutang: (json['pph21_terutang'] as num).toDouble(),
      pph21DipotongSebelumnya: (json['pph21_dipotong_sebelumnya'] as num).toDouble(),
      totalPph21Withheld: (json['total_pph21_withheld'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'neto_salary': netoSalary,
      'ptkp': ptkp,
      'pkp': pkp,
      'pph21_terutang': pph21Terutang,
      'pph21_dipotong_sebelumnya': pph21DipotongSebelumnya,
      'total_pph21_withheld': totalPph21Withheld,
    };
  }
}

/// Model untuk detail bukti potong 1721-A1
class TaxFormDetailModel {
  final int id;
  final String formNumber;
  final int taxYear;
  final TaxFormCompanyInfo company;
  final TaxFormEmployeeInfo employee;
  final String workPeriod;
  final PenghasilanBruto penghasilanBruto;
  final Pengurang pengurang;
  final PerhitunganPph perhitunganPph;
  final String? generatedAt;

  const TaxFormDetailModel({
    required this.id,
    required this.formNumber,
    required this.taxYear,
    required this.company,
    required this.employee,
    required this.workPeriod,
    required this.penghasilanBruto,
    required this.pengurang,
    required this.perhitunganPph,
    this.generatedAt,
  });

  factory TaxFormDetailModel.fromJson(Map<String, dynamic> json) {
    return TaxFormDetailModel(
      id: json['id'],
      formNumber: json['form_number'],
      taxYear: json['tax_year'],
      company: TaxFormCompanyInfo.fromJson(json['company']),
      employee: TaxFormEmployeeInfo.fromJson(json['employee']),
      workPeriod: json['work_period'],
      penghasilanBruto: PenghasilanBruto.fromJson(json['penghasilan_bruto']),
      pengurang: Pengurang.fromJson(json['pengurang']),
      perhitunganPph: PerhitunganPph.fromJson(json['perhitungan_pph']),
      generatedAt: json['generated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form_number': formNumber,
      'tax_year': taxYear,
      'company': company.toJson(),
      'employee': employee.toJson(),
      'work_period': workPeriod,
      'penghasilan_bruto': penghasilanBruto.toJson(),
      'pengurang': pengurang.toJson(),
      'perhitungan_pph': perhitunganPph.toJson(),
      'generated_at': generatedAt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaxFormDetailModel &&
        other.id == id &&
        other.formNumber == formNumber &&
        other.taxYear == taxYear;
  }

  @override
  int get hashCode {
    return id.hashCode ^ formNumber.hashCode ^ taxYear.hashCode;
  }
}

/// Model untuk download URL
class TaxFormDownloadModel {
  final String downloadUrl;
  final String filename;

  const TaxFormDownloadModel({
    required this.downloadUrl,
    required this.filename,
  });

  factory TaxFormDownloadModel.fromJson(Map<String, dynamic> json) {
    return TaxFormDownloadModel(
      downloadUrl: json['download_url'],
      filename: json['filename'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'download_url': downloadUrl,
      'filename': filename,
    };
  }
}
