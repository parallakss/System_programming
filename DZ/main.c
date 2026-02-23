#include <stdio.h>
#include <stdlib.h>

// Прототипы функций из ассемблерного модуля
extern void* queue_init(long capacity);
extern int queue_push_back(void* queue, long value);
extern long queue_pop_front(void* queue);
extern void queue_fill_random(void* queue, long count);
extern void queue_remove_even(void* queue);
extern long queue_count_ends_with_1(void* queue);
extern long queue_count_even(void* queue);
extern long queue_size(void* queue);
extern int queue_is_empty(void* queue);
extern void queue_destroy(void* queue);

// Функция для вывода всех элементов очереди (без изменения)
void print_queue(void* queue) {
    long size = queue_size(queue);
    printf("Размер очереди: %ld\n", size);
    printf("Элементы: ");
    
    if (size == 0) {
        printf("(пусто)\n");
        return;
    }
    
    // Создаем временный массив для хранения элементов
    long* temp = malloc(size * sizeof(long));
    if (!temp) {
        printf("Ошибка выделения памяти\n");
        return;
    }
    
    // Извлекаем все элементы и сохраняем во временный массив
    for (int i = 0; i < size; i++) {
        temp[i] = queue_pop_front(queue);
    }
    
    // Выводим элементы
    for (int i = 0; i < size; i++) {
        printf("%ld ", temp[i]);
    }
    printf("\n");
    
    // Возвращаем элементы обратно в очередь
    for (int i = 0; i < size; i++) {
        queue_push_back(queue, temp[i]);
    }
    
    free(temp);
}

int main() {
    printf("=== Демонстрация работы очереди на ассемблере ===\n\n");
    
    // 1. Инициализация
    void* queue = queue_init(4);
    printf("1. Очередь инициализирована\n");
    print_queue(queue);
    
    // 2. Добавление элементов
    printf("\n2. Добавляем элементы: 10, 21, 30, 41, 52\n");
    queue_push_back(queue, 10);
    queue_push_back(queue, 21);
    queue_push_back(queue, 30);
    queue_push_back(queue, 41);
    queue_push_back(queue, 52);
    printf("После добавления элементов:\n");
    print_queue(queue);
    
    // 3. Количество четных чисел
    printf("\n3. Количество четных чисел: %ld\n", queue_count_even(queue));
    
    // 4. Количество чисел, оканчивающихся на 1
    printf("\n4. Количество чисел, оканчивающихся на 1: %ld\n", queue_count_ends_with_1(queue));
    
    // 5. Удаление из начала
    printf("\n5. Удаляем элементы из начала:\n");
    printf("   Извлечено: %ld\n", queue_pop_front(queue));
    printf("   Извлечено: %ld\n", queue_pop_front(queue));
    printf("После удаления двух элементов:\n");
    print_queue(queue);
    
    // 6. Заполнение случайными числами
    printf("\n6. Заполняем очередь 5 случайными числами\n");
    queue_fill_random(queue, 5);
    printf("После заполнения случайными числами:\n");
    print_queue(queue);
    
    // 7. Статистика после случайного заполнения
    printf("\n7. Статистика после случайного заполнения:\n");
    printf("   Четных чисел: %ld\n", queue_count_even(queue));
    printf("   Числа, оканчивающихся на 1: %ld\n", queue_count_ends_with_1(queue));
    
    // 8. Удаление четных чисел
    printf("\n8. Удаляем все четные числа (нечетные добавляются обратно)\n");
    queue_remove_even(queue);
    printf("После удаления четных чисел:\n");
    print_queue(queue);
    
    // 9. Финальная статистика
    printf("\n9. Финальная статистика:\n");
    printf("   Четных чисел: %ld\n", queue_count_even(queue));
    printf("   Числа, оканчивающихся на 1: %ld\n", queue_count_ends_with_1(queue));
    
    // 10. Очистка
    printf("\n10. Память освобождается\n");
    queue_destroy(queue);
    
    return 0;
}