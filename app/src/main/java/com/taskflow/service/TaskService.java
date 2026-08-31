package com.taskflow.service;

import com.taskflow.dto.TaskRequest;
import com.taskflow.dto.TaskResponse;
import com.taskflow.entity.Task;
import com.taskflow.entity.TaskStatus;
import com.taskflow.exception.TaskNotFoundException;
import com.taskflow.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class TaskService {

    private final TaskRepository taskRepository;

    public List<TaskResponse> getAllTasks() {
        log.info("Fetching all tasks");
        return taskRepository.findAll().stream()
                .map(TaskResponse::from)
                .collect(Collectors.toList());
    }

    public TaskResponse getTaskById(Long id) {
        log.info("Fetching task id={}", id);
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new TaskNotFoundException(id));
        return TaskResponse.from(task);
    }

    @Transactional
    public TaskResponse createTask(TaskRequest request) {
        Task task = Task.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .status(request.getStatus() != null ? request.getStatus() : TaskStatus.TODO)
                .build();
        Task saved = taskRepository.save(task);
        log.info("Created task id={}", saved.getId());
        return TaskResponse.from(saved);
    }

    @Transactional
    public TaskResponse updateTask(Long id, TaskRequest request) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new TaskNotFoundException(id));
        task.setTitle(request.getTitle());
        task.setDescription(request.getDescription());
        if (request.getStatus() != null) {
            task.setStatus(request.getStatus());
        }
        Task updated = taskRepository.save(task);
        log.info("Updated task id={}", updated.getId());
        return TaskResponse.from(updated);
    }

    @Transactional
    public void deleteTask(Long id) {
        if (!taskRepository.existsById(id)) {
            throw new TaskNotFoundException(id);
        }
        taskRepository.deleteById(id);
        log.info("Deleted task id={}", id);
    }
}
