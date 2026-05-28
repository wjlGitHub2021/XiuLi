import SwiftUI
import UIKit
import ImageIO

struct TaskCompleteSheet: View {
    let task: TaskItem
    let onCompleted: (TaskItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showSourcePicker = false
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var showAlreadyCompletedAlert = false

    private let taskService = TaskService()

    var body: some View {
        NavigationStack {
            ZStack {
                DLBackground()

                ScrollView {
                    VStack(spacing: Spacing.section) {
                        DLGlassPageHeader(title: "完成任务", subtitle: "上传照片作为完成凭证")

                        DLGlassCard(tint: Color.dlLavender, cornerRadius: CornerRadius.panel) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: taskIcon)
                                    .font(.title3)
                                    .foregroundStyle(Color.dlLavender)
                                    .frame(width: 44, height: 44)
                                    .glassEffect(.regular.tint(Color.dlLavender.opacity(0.18)), in: .circle)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("打卡")
                                        .font(.caption)
                                        .foregroundStyle(Color.dlTextSecondary)
                                    Text(task.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.dlTextPrimary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)

                        if let image = selectedImage {
                            DLGlassCard(cornerRadius: CornerRadius.panel) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 320)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.panel, style: .continuous))
                            }
                            .padding(.horizontal, Spacing.screenHorizontal)
                        } else {
                            DLGlassCard(cornerRadius: CornerRadius.panel) {
                                VStack(spacing: Spacing.sm) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.dlLavender.opacity(0.18))
                                            .frame(width: 72, height: 72)
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30, weight: .semibold))
                                            .foregroundStyle(Color.dlLavender)
                                    }
                                    Text("请上传打卡照片")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.dlTextPrimary)
                                    Text("可从相册或相机选择")
                                        .font(.caption)
                                        .foregroundStyle(Color.dlTextSecondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 220)
                            }
                            .padding(.horizontal, Spacing.screenHorizontal)
                        }

                        Button {
                            showSourcePicker = true
                        } label: {
                            Label("选择照片", systemImage: "photo.on.rectangle")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                        }
                        .buttonStyle(.glass)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .disabled(isUploading)

                        if selectedImage != nil {
                            DLPrimaryButton(
                                action: { Task { await submitCompletion() } },
                                isLoading: isUploading,
                                isDisabled: false
                            ) {
                                Text("确认完成")
                            }
                            .padding(.horizontal, Spacing.screenHorizontal)
                        }

                        if let errorMessage {
                            DLErrorBanner(message: errorMessage)
                                .padding(.horizontal, Spacing.screenHorizontal)
                        }
                    }
                    .padding(.vertical, Spacing.screenVertical)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("完成任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .disabled(isUploading)
                        .buttonStyle(.glass)
                }
            }
            .tint(Color.dlLavender)
            .confirmationDialog("选择照片来源", isPresented: $showSourcePicker) {
                Button("拍照") { showCamera = true }
                Button("从相册选择") { showPhotoLibrary = true }
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoPicker(image: $selectedImage)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(image: $selectedImage)
            }
            .alert("提示", isPresented: $showAlreadyCompletedAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("该任务今日已完成")
            }
        }
    }

    private var taskIcon: String {
        switch task.taskType {
        case .daily: "sun.max.fill"
        case .weekly: "calendar.badge.checkmark"
        case .monthly: "chart.line.uptrend.xyaxis"
        }
    }

    private func submitCompletion() async {
        guard let image = selectedImage else { return }
        isUploading = true
        errorMessage = nil
        defer { isUploading = false }

        guard let data = compressImage(image, maxWidth: 800, quality: 0.5) else {
            errorMessage = "图片处理失败"
            return
        }

        do {
            let timestamp = Int(Date().timeIntervalSince1970)
            let path = "\(task.id.uuidString)-\(timestamp).jpg"
            try await AppSupabase.client.storage
                .from("task-proofs")
                .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: false))

            let response = try await taskService.completeTask(taskId: task.id)
            if response.alreadyCompleted {
                showAlreadyCompletedAlert = true
            } else {
                onCompleted(response.task)
                dismiss()
            }
        } catch is CancellationError {
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = "上传失败：\(error.localizedDescription)"
        }
    }

    private func compressImage(_ image: UIImage, maxWidth: CGFloat, quality: CGFloat) -> Data? {
        if let baseJPEG = image.jpegData(compressionQuality: 1.0),
           let source = CGImageSourceCreateWithData(baseJPEG as CFData, nil) {
            let maxPixel = max(maxWidth, maxWidth * image.size.height / max(image.size.width, 1))
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(maxPixel),
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            if let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                return UIImage(cgImage: cg).jpegData(compressionQuality: quality)
            }
        }
        let ratio = min(1, maxWidth / max(image.size.width, 1))
        let target = CGSize(width: floor(image.size.width * ratio), height: floor(image.size.height * ratio))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
        return resized.jpegData(compressionQuality: quality)
    }
}
