package com.taskflow.service;

import com.taskflow.dto.TaskRequest;
import com.taskflow.dto.TaskResponse;
import com.taskflow.entity.Task;
import com.taskflow.entity.TaskStatus;
import com.taskflow.exception.TaskNotFoundException;
import com.taskflow.repository.TaskRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TaskServiceTest {

    @Mock
    private TaskRepository taskRepository;

    @InjectMocks
    private TaskService taskService;

    private Task sampleTask() {
        return Task.builder()
                .id(1L)
                .title("Sample task")
                .description("A description")
                .status(TaskStatus.TODO)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    @Test
    void getAllTasks_returnsMappedList() {
        when(taskRepository.findAll()).thenReturn(List.of(sampleTask()));

        List<TaskResponse> result = taskService.getAllTasks();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getTitle()).isEqualTo("Sample task");
    }

    @Test
    void getTaskById_existingId_returnsTask() {
        when(taskRepository.findById(1L)).thenReturn(Optional.of(sampleTask()));

        TaskResponse result = taskService.getTaskById(1L);

        assertThat(result.getId()).isEqualTo(1L);
    }

    @Test
    void getTaskById_missingId_throwsNotFoundException() {
        when(taskRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.getTaskById(99L))
                .isInstanceOf(TaskNotFoundException.class)
                .hasMessageContaining("99");
    }

    @Test
    void createTask_noStatusProvided_defaultsToTodo() {
        TaskRequest request = new TaskRequest();
        request.setTitle("New task");

        when(taskRepository.save(any(Task.class))).thenReturn(sampleTask());

        taskService.createTask(request);

        verify(taskRepository).save(argThat(t -> t.getStatus() == TaskStatus.TODO));
    }

    @Test
    void createTask_withStatus_usesProvidedStatus() {
        TaskRequest request = new TaskRequest();
        request.setTitle("In-flight task");
        request.setStatus(TaskStatus.IN_PROGRESS);

        Task inProgress = sampleTask();
        inProgress.setStatus(TaskStatus.IN_PROGRESS);
        when(taskRepository.save(any(Task.class))).thenReturn(inProgress);

        TaskResponse result = taskService.createTask(request);

        assertThat(result.getStatus()).isEqualTo(TaskStatus.IN_PROGRESS);
    }

    @Test
    void updateTask_missingId_throwsNotFoundException() {
        when(taskRepository.findById(99L)).thenReturn(Optional.empty());

        TaskRequest request = new TaskRequest();
        request.setTitle("Update");

        assertThatThrownBy(() -> taskService.updateTask(99L, request))
                .isInstanceOf(TaskNotFoundException.class);
    }

    @Test
    void updateTask_existingId_savesUpdatedFields() {
        Task existing = sampleTask();
        when(taskRepository.findById(1L)).thenReturn(Optional.of(existing));
        when(taskRepository.save(any(Task.class))).thenReturn(existing);

        TaskRequest request = new TaskRequest();
        request.setTitle("Updated title");
        request.setStatus(TaskStatus.DONE);

        taskService.updateTask(1L, request);

        verify(taskRepository).save(argThat(t ->
                t.getTitle().equals("Updated title") && t.getStatus() == TaskStatus.DONE));
    }

    @Test
    void deleteTask_missingId_throwsNotFoundException() {
        when(taskRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> taskService.deleteTask(99L))
                .isInstanceOf(TaskNotFoundException.class);
    }

    @Test
    void deleteTask_existingId_callsDeleteById() {
        when(taskRepository.existsById(1L)).thenReturn(true);

        taskService.deleteTask(1L);

        verify(taskRepository).deleteById(1L);
    }
}
