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
            .alert("提示", isPresented: $showAlreadyCompletedAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("该任务今日已完成")
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
            // 切 sheet / 视图重组导致的取消，不弹错误
        } catch let urlError as URLError where urlError.code == .cancelled {
        } catch {
            errorMessage = "上传失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Image Compression

    // Bug #2 修复：原 UIGraphicsImageRenderer 路径对 HEIF HDR/wide-gamut 图像输出可能损坏，
    // 导致 Supabase Storage 写入时报"new row violates row-level security policy"（实为 metadata 校验失败）。
    // 改为：优先用 ImageIO 走原始 JPEG/HEIF Data 重新编码；失败回退到强制 SDR 的 renderer。
    private func compressImage(_ image: UIImage, maxWidth: CGFloat, quality: CGFloat) -> Data? {
        // 优先：UIImage → 原始 JPEG Data → CGImageSource → 缩略图。
        // 不走原图 Data 是因为 PhotoPicker 已经把 HEIF 解码成 UIImage，但 jpegData 重新编码会丢色彩信息并标准化为 sRGB，
        // 输出永远是合法的 JPEG 字节序列。
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
        // 回退：强制 SDR + 1x scale + 不透明的 renderer，避免 HDR/alpha 通道引发的损坏
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
