import SwiftUI
import UIKit

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

    private let taskService = TaskService()

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                Text("完成任务：\(task.title)")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.md)

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("请上传打卡照片")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }

                Button("选择照片") { showSourcePicker = true }
                    .buttonStyle(.glassProminent)
                    .disabled(isUploading)

                if selectedImage != nil {
                    Button(action: { Task { await submitCompletion() } }) {
                        if isUploading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("确认完成")
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(isUploading)
                }

                if let errorMessage {
                    DLErrorBanner(message: errorMessage)
                }

                Spacer()
            }
            .padding(Spacing.md)
            .navigationTitle("打卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .disabled(isUploading)
                }
            }
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
        }
    }

    // MARK: - Submit

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
            // TODO: Create 'task-proofs' bucket in Supabase Storage dashboard before first use
            let path = "\(task.id.uuidString).jpg"
            try await AppSupabase.client.storage
                .from("task-proofs")
                .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))

            let response = try await taskService.completeTask(taskId: task.id)
            onCompleted(response.task)
            dismiss()
        } catch {
            errorMessage = "上传失败，请重试"
        }
    }

    // MARK: - Image Compression

    private func compressImage(_ image: UIImage, maxWidth: CGFloat, quality: CGFloat) -> Data? {
        let ratio = maxWidth / image.size.width
        let newSize: CGSize
        if ratio < 1 {
            newSize = CGSize(width: maxWidth, height: image.size.height * ratio)
        } else {
            newSize = image.size
        }
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized?.jpegData(compressionQuality: quality)
    }
}
