import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit


struct AddEditMedicationView: View {
    
    
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    
    
    let mode: AppRoute.MedicationEditorMode
    
    
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var selectedCategory: MedicationCategory = .vitamins
    
    @State private var time: Date = Date()
    @State private var startDate: Date = Date()
    
    @State private var frequencySelection: FrequencySelection = .daily
    @State private var customWeekdays: Set<Weekday> = [.monday, .wednesday, .friday]
    
    @State private var packagingUIImage: UIImage? = nil
    @State private var instructionUIImage: UIImage? = nil
    @State private var instructionPDFData: Data? = nil
    @State private var instructionPDFFileName: String? = nil
    @State private var existingPackagingRef: AttachmentRef? = nil
    @State private var existingInstructionRef: AttachmentRef? = nil
    @State private var existingPackagingUIImage: UIImage? = nil
    @State private var existingInstructionUIImage: UIImage? = nil
    @State private var didPreload: Bool = false
    
    @State private var showPackagingDialog: Bool = false
    @State private var showInstructionDialog: Bool = false
    
    @State private var showPackagingCamera: Bool = false
    @State private var showInstructionCamera: Bool = false
    
    @State private var showPackagingGallerySheet: Bool = false
    @State private var showInstructionGallerySheet: Bool = false
    
    @State private var packagingPickerItem: PhotosPickerItem? = nil
    @State private var instructionPickerItem: PhotosPickerItem? = nil
    
    @State private var showPackagingGallery: Bool = false
    @State private var showInstructionGallery: Bool = false
    
    @State private var showPDFImporter: Bool = false
    
    @State private var showTimeSheet: Bool = false
    @State private var showStartDateSheet: Bool = false
    
    @State private var showCustomDaysFullScreen: Bool = false
    @State private var showDeleteConfirm: Bool = false
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case name, dosage }
    
    
    private let sidePadding: CGFloat = 20
    private let bottomSafePaddingToButton: CGFloat = 20
    private let saveHeight: CGFloat = 54
    private let saveCorner: CGFloat = 16
    
    private var scrollBottomInset: CGFloat {
        saveHeight + bottomSafePaddingToButton + 18
    }
    
    
    private var screenTitle: String {
        switch mode {
        case .create: return "Add Pill"
        case .edit: return "Edit Pill"
        }
    }
    
    private var isSaveEnabled: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDosage = !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPackaging = (packagingUIImage != nil) || (existingPackagingRef != nil)
        let hasInstruction = (instructionUIImage != nil) || (instructionPDFData != nil) || (existingInstructionRef != nil)
        
        return hasName && hasDosage && hasPackaging && hasInstruction
    }
    
    
    init(mode: AppRoute.MedicationEditorMode) {
        self.mode = mode
    }
    
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
            
                AppNavBar(
                    title: screenTitle,
                    showsBack: true,
                    onBackTap: { dismiss() }
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        
                        SectionCard(title: "Name") {
                            InsetField {
                                TextField("", text: $name)
                                    .focused($focusedField, equals: .name)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled(false)
                                    .font(AppFont.poppins(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        SectionCard(title: "Dosage Mg") {
                            InsetField {
                                TextField("", text: $dosage)
                                    .focused($focusedField, equals: .dosage)
                                    .keyboardType(.numberPad)
                                    .font(AppFont.poppins(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        SectionCard(title: "Category") {
                            Menu {
                                Button("Vitamins") { selectedCategory = .vitamins }
                                Button("Medicines") { selectedCategory = .medicines }
                                Button("Supplements") { selectedCategory = .supplements }
                            } label: {
                                InsetField {
                                    HStack {
                                        Text(selectedCategory.title)
                                            .font(AppFont.poppins(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "triangle.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AppColors.yellow)
                                            .rotationEffect(.degrees(180))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        SectionCard(title: "Photos Of The Packaging: (Gallery)") {
                            Button { showPackagingDialog = true } label: {
                                AttachmentInset(image: packagingUIImage ?? existingPackagingUIImage)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        SectionCard(title: "Instructions(Photo/PDF From Files)") {
                            Button { showInstructionDialog = true } label: {
                                AttachmentInset(
                                    image: instructionUIImage ?? existingInstructionUIImage,
                                    showsPDFBadge: shouldShowInstructionPDFBadge
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        SectionCard(title: "TimePicker") {
                            Button {
                                focusedField = nil
                                showTimeSheet = true
                            } label: {
                                InsetField {
                                    HStack {
                                        Text(timeFormatted(time))
                                            .font(AppFont.poppins(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "triangle.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AppColors.yellow)
                                            .rotationEffect(.degrees(180))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        SectionCard(title: "Date Picker") {
                            Button {
                                focusedField = nil
                                showStartDateSheet = true
                            } label: {
                                InsetField {
                                    HStack {
                                        Text(dateFormatted(startDate))
                                            .font(AppFont.poppins(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "triangle.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AppColors.yellow)
                                            .rotationEffect(.degrees(180))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        SectionCard(title: "Frequency") {
                            Menu {
                                Button("Daily") { frequencySelection = .daily }
                                Button("Every other day") { frequencySelection = .everyOtherDay }
                                Button("Weekdays") { frequencySelection = .weekdays }
                                Button("Custom") {
                                    frequencySelection = .custom
                                    showCustomDaysFullScreen = true
                                }
                            } label: {
                                InsetField {
                                    HStack {
                                        Text(frequencyTitle)
                                            .font(AppFont.poppins(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "triangle.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(AppColors.yellow)
                                            .rotationEffect(.degrees(180))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                       
                        Spacer(minLength: scrollBottomInset)
                    }
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 12)
                    
                    VStack(spacing: 10) {
                        Button {
                            save()
                        } label: {
                            Text("Save")
                                .font(AppFont.poppins(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: saveHeight)
                                .background(isSaveEnabled ? AppColors.yellow : AppColors.gray.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: saveCorner, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!isSaveEnabled)

                        if isEditMode {
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                Text("Delete")
                                    .font(AppFont.poppins(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: saveHeight)
                                    .background(Color(hex: "B70F0F"))
                                    .clipShape(RoundedRectangle(cornerRadius: saveCorner, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, sidePadding)
                    .padding(.bottom, bottomSafePaddingToButton)
                }
            }
            
            
            
        }
        
        
        .navigationBarHidden(true)
        
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                    hideKeyboard()
                }
                .font(AppFont.poppins(size: 16, weight: .semibold))
                .foregroundColor(AppColors.yellow)
            }
        }
        
        .toolbar(.hidden, for: .tabBar)
        
        .onAppear { preloadIfNeeded() }
        
        .confirmationDialog("Packaging photo", isPresented: $showPackagingDialog, titleVisibility: .visible) {
            Button("Take photo") { showPackagingCamera = true }
            Button("Choose from gallery") { showPackagingGallery = true }
            Button("Cancel", role: .cancel) { }
        }

        .confirmationDialog("Instructions", isPresented: $showInstructionDialog, titleVisibility: .visible) {
            Button("Take photo") { showInstructionCamera = true }
            Button("Choose photo from gallery") { showInstructionGallery = true }
            Button("Choose PDF from Files") { showPDFImporter = true }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog("Delete medication?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if case .edit(let id) = mode {
                    store.deleteMedication(id: id)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the medication, its events, and pending reminders.")
        }
        
        .fullScreenCover(isPresented: $showPackagingCamera) {
            ImagePicker(sourceType: .camera) { img in
                setNewPackagingImage(img)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showInstructionCamera) {
            ImagePicker(sourceType: .camera) { img in
                setNewInstructionImage(img)
            }
            .ignoresSafeArea()
        }
        
        .sheet(isPresented: $showPackagingGallery) {
            PhotoLibraryPicker(
                onPicked: { image in
                    setNewPackagingImage(image)
                    showPackagingGallery = false
                },
                onCancel: {
                    showPackagingGallery = false
                }
            )
            .ignoresSafeArea()
        }

        .sheet(isPresented: $showInstructionGallery) {
            PhotoLibraryPicker(
                onPicked: { image in
                    setNewInstructionImage(image)
                    showInstructionGallery = false
                },
                onCancel: {
                    showInstructionGallery = false
                }
            )
            .ignoresSafeArea()
        }
        .onChange(of: packagingPickerItem) { newItem in
            guard let newItem else { return }
            loadImage(from: newItem) { img in
                setNewPackagingImage(img)
                showPackagingGallerySheet = false
            }
        }
        
        .sheet(isPresented: $showInstructionGallerySheet) {
            GalleryPickerSheet(title: "Choose instruction photo", pickerItem: $instructionPickerItem)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: instructionPickerItem) { newItem in
            guard let newItem else { return }
            loadImage(from: newItem) { img in
                setNewInstructionImage(img)
                showInstructionGallerySheet = false
            }
        }
        
        .fileImporter(
            isPresented: $showPDFImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handlePDFImport(result)
        }
        
        .sheet(isPresented: $showTimeSheet) {
            PickerSheet(title: "Time", onDone: { showTimeSheet = false }) {
                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .tint(AppColors.yellow)
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        
        .sheet(isPresented: $showStartDateSheet) {
            PickerSheet(title: "Start date", onDone: { showStartDateSheet = false }) {
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .tint(AppColors.yellow)
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        
        .fullScreenCover(isPresented: $showCustomDaysFullScreen) {
            CustomWeekdaysFullScreen(
                selected: $customWeekdays,
                onClose: { showCustomDaysFullScreen = false }
            )
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil,
                                        from: nil,
                                        for: nil)
    }
    
    
    
    private func preloadIfNeeded() {
        guard !didPreload else { return }
        didPreload = true

        switch mode {
        case .create:
            return
        case .edit(let id):
            guard let med = store.medication(by: id) else { return }
            
            name = med.name
            dosage = med.subtitle
                .replacingOccurrences(of: " mg", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            selectedCategory = med.category
            time = dateFromTimeOfDay(med.intakeTime)
            
            if let mapped = med.expiryDate { startDate = mapped }
            
            switch med.frequency {
            case .daily:
                frequencySelection = .daily
            case .everyOtherDay:
                frequencySelection = .everyOtherDay
            case .weekdays:
                frequencySelection = .weekdays
            case .customWeekdays(let days):
                frequencySelection = .custom
                customWeekdays = days
            }

            existingPackagingRef = med.attachments.first(where: { $0.kind == .packagePhoto })
            if let packagingRef = existingPackagingRef {
                existingPackagingUIImage = loadExistingImage(relativePath: packagingRef.relativePath)
            }

            if let instructionPhoto = med.attachments.first(where: { $0.kind == .instructionPhoto }) {
                existingInstructionRef = instructionPhoto
                existingInstructionUIImage = loadExistingImage(relativePath: instructionPhoto.relativePath)
            } else if let instructionPDF = med.attachments.first(where: { $0.kind == .instructionPDF }) {
                existingInstructionRef = instructionPDF
                existingInstructionUIImage = nil
            }
        }
    }
    
    
    private func save() {
        var attachments: [AttachmentRef] = []
        
        if let img = packagingUIImage {
            do {
                let relPath = try LocalAttachmentsManager.shared.saveJPEG(image: img, compressionQuality: 0.9)
                attachments.append(AttachmentRef(kind: .packagePhoto, relativePath: relPath))
            } catch {
                return
            }
        } else if let existingPackagingRef {
            attachments.append(existingPackagingRef)
        }
        
        if let img = instructionUIImage {
            do {
                let relPath = try LocalAttachmentsManager.shared.saveJPEG(image: img, compressionQuality: 0.9)
                attachments.append(AttachmentRef(kind: .instructionPhoto, relativePath: relPath))
            } catch {
                return
            }
        } else if let pdf = instructionPDFData {
            do {
                let relPath = try LocalAttachmentsManager.shared.saveData(pdf, fileExtension: "pdf")
                attachments.append(AttachmentRef(kind: .instructionPDF, relativePath: relPath))
            } catch {
                return
            }
        } else if let existingInstructionRef {
            attachments.append(existingInstructionRef)
        }
        
        let freq: MedicationFrequency = {
            switch frequencySelection {
            case .daily:
                return .daily
            case .everyOtherDay:
                return .everyOtherDay(anchor: startDate)
            case .weekdays:
                return .weekdays
            case .custom:
                return .customWeekdays(customWeekdays)
            }
        }()
        
        let med = Medication(
            id: existingIdIfEdit(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: "\(dosage.trimmingCharacters(in: .whitespacesAndNewlines)) mg",
            category: selectedCategory,
            expiryDate: startDate,
            intakeTime: TimeOfDay(date: time),
            frequency: freq,
            notificationsEnabled: existingNotificationsEnabledIfEdit() ?? true,
            attachments: attachments,
            createdAt: existingCreatedAtIfEdit() ?? Date(),
            updatedAt: Date()
        )
        
        switch mode {
        case .create:
            store.addMedication(med)
        case .edit:
            store.updateMedication(med)
        }
        
        dismiss()
    }
    
    private func existingIdIfEdit() -> UUID {
        switch mode {
        case .create: return UUID()
        case .edit(let id): return id
        }
    }
    
    private func existingCreatedAtIfEdit() -> Date? {
        switch mode {
        case .create: return nil
        case .edit(let id): return store.medication(by: id)?.createdAt
        }
    }

    private func existingNotificationsEnabledIfEdit() -> Bool? {
        switch mode {
        case .create: return nil
        case .edit(let id): return store.medication(by: id)?.notificationsEnabled
        }
    }
    
    
    private var frequencyTitle: String {
        switch frequencySelection {
        case .daily:
            return "Daily"
        case .everyOtherDay:
            return "Every other day"
        case .weekdays:
            return "Weekdays"
        case .custom:
            let sorted = customWeekdays.sorted()
            if sorted.isEmpty { return "Custom" }
            let joined = sorted.map { $0.shortTitle }.joined(separator: ", ")
            return "Custom (\(joined))"
        }
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    
    private func timeFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "H:mm"
        return f.string(from: date)
    }
    
    private func dateFormatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "d MMM yyyy"
        return f.string(from: date)
    }
    
    private func dateFromTimeOfDay(_ t: TimeOfDay) -> Date {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "en_US_POSIX")
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = t.hour
        comps.minute = t.minute
        return cal.date(from: comps) ?? Date()
    }
    
    
    private func loadImage(from item: PhotosPickerItem, completion: @escaping (UIImage) -> Void) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run { completion(image) }
            }
        }
    }

    private var shouldShowInstructionPDFBadge: Bool {
        if instructionPDFData != nil { return true }
        if instructionUIImage != nil { return false }
        if existingInstructionUIImage != nil { return false }
        return existingInstructionRef?.kind == .instructionPDF
    }

    private func loadExistingImage(relativePath: String) -> UIImage? {
        guard
            let url = try? LocalAttachmentsManager.shared.url(forRelativePath: relativePath),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return UIImage(data: data)
    }

    private func setNewPackagingImage(_ image: UIImage) {
        packagingUIImage = image
        existingPackagingRef = nil
        existingPackagingUIImage = nil
    }

    private func setNewInstructionImage(_ image: UIImage) {
        instructionUIImage = image
        instructionPDFData = nil
        instructionPDFFileName = nil
        existingInstructionRef = nil
        existingInstructionUIImage = nil
    }

    private func setNewInstructionPDF(_ data: Data, fileName: String?) {
        instructionPDFData = data
        instructionPDFFileName = fileName
        instructionUIImage = nil
        existingInstructionRef = nil
        existingInstructionUIImage = nil
    }
    
    
    private func handlePDFImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            
            setNewInstructionPDF(try Data(contentsOf: url), fileName: url.lastPathComponent)
        } catch { }
    }
}


private enum FrequencySelection {
    case daily
    case everyOtherDay
    case weekdays
    case custom
}


private struct SectionCard<Content: View>: View {
    
    let title: String
    @ViewBuilder let content: Content
    
    private let outerCorner: CGFloat = 18
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.poppins(size: 13, weight: .semibold))
                .foregroundColor(AppColors.yellow)
            
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: outerCorner, style: .continuous)
                .fill(AppColors.cardSwamp.opacity(0.60))
        )
    }
}

private struct InsetField<Content: View>: View {
    
    @ViewBuilder let content: Content
    
    private let innerCorner: CGFloat = 16
    private let height: CGFloat = 52
    
    var body: some View {
        content
            .padding(.horizontal, 16)
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
    }
}

private struct AttachmentInset: View {
    
    let image: UIImage?
    var showsPDFBadge: Bool = false
    
    private let innerCorner: CGFloat = 16
    private let height: CGFloat = 165
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: innerCorner, style: .continuous)
                .fill(Color.white.opacity(0.08))
            
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: innerCorner, style: .continuous))
            } else {
                CameraPlusIcon()
            }
            
            if showsPDFBadge {
                VStack {
                    HStack {
                        Spacer()
                        Text("PDF")
                            .font(AppFont.poppins(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColors.yellow)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(12)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

private struct CameraPlusIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "camera.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.yellow)
            
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.yellow)
                }
                Spacer()
            }
            .frame(width: 52, height: 40)
            .offset(x: 10, y: -10)
        }
    }
}


private struct GalleryPickerSheet: View {
    
    let title: String
    @Binding var pickerItem: PhotosPickerItem?
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 16) {
                HStack {
                    Text(title)
                        .font(AppFont.poppins(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.yellow)
                    Spacer()
                }
                .padding(.horizontal, AppLayout.sidePadding)
                .padding(.top, 16)
                
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("Open Gallery")
                        .font(AppFont.poppins(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, AppLayout.sidePadding)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
    }
}


private struct PickerSheet<Content: View>: View {
    
    let title: String
    let onDone: () -> Void
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack {
                    Text(title)
                        .font(AppFont.poppins(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.yellow)
                    
                    Spacer()
                    
                    Button("Done") { onDone() }
                        .font(AppFont.poppins(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.yellow)
                }
                .padding(.horizontal, AppLayout.sidePadding)
                .padding(.top, 12)
                
                content
                    .padding(.horizontal, AppLayout.sidePadding)
                
                Spacer()
            }
        }
    }
}


private struct CustomWeekdaysFullScreen: View {
    
    @Binding var selected: Set<Weekday>
    let onClose: () -> Void
    
    private let order: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                AppNavBar(title: "Custom days", showsBack: true, onBackTap: onClose)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(order) { day in
                            Button {
                                toggle(day)
                            } label: {
                                HStack {
                                    Text(day.shortTitle)
                                        .font(AppFont.poppins(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: selected.contains(day) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(selected.contains(day) ? AppColors.green : AppColors.gray)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(AppColors.cardSwamp.opacity(0.60))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, AppLayout.sidePadding)
                    .padding(.top, 12)
                }
            }
        }
    }
    
    private func toggle(_ day: Weekday) {
        if selected.contains(day) {
            selected.remove(day)
        } else {
            selected.insert(day)
        }
    }
}


private struct ImagePicker: UIViewControllerRepresentable {
    
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    init(sourceType: UIImagePickerController.SourceType, onImagePicked: @escaping (UIImage) -> Void) {
        self.sourceType = sourceType
        self.onImagePicked = onImagePicked
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        let onImagePicked: (UIImage) -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
}


#Preview {
    NavigationStack {
        AddEditMedicationView(mode: .create)
            .environmentObject(AppStore())
    }
}

import SwiftUI
import PhotosUI
import UIKit

struct PhotoLibraryPicker: UIViewControllerRepresentable {

    let onPicked: (UIImage) -> Void

    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, onCancel: onCancel)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {

        private let onPicked: (UIImage) -> Void
        private let onCancel: () -> Void

        init(onPicked: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onPicked = onPicked
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                onCancel()
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    guard let image = object as? UIImage else {
                        DispatchQueue.main.async { self.onCancel() }
                        return
                    }
                    DispatchQueue.main.async { self.onPicked(image) }
                }
            } else {
                onCancel()
            }
        }
    }
}
